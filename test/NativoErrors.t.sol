// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.10;

import "forge-std/Test.sol";

import {Nativo, ERC20} from "src/Nativo.sol";

contract NativoErrorsTest is Test {
    Nativo public nativo;
    address EOA = makeAddr("EOA");
    address manager = makeAddr("managerAndTreasury");

    function setUp() public virtual {
        vm.roll(1);
        vm.warp(1);

        vm.prank(manager);
        // name and symbol depend on the blockchain we are deploying
        nativo = new Nativo("Wrapped Nativo crypto", "wANY");
    }

    function testWithdraw() public {
        vm.expectRevert(ERC20.InsufficientBalance.selector);
        nativo.withdraw(1);

        // withdraw to address(this) should fail because
        // this contract doesnt have a fallback function

        nativo.deposit{value: 1}();
        vm.expectRevert(Nativo.WithdrawFailed.selector);
        nativo.withdraw(1);

        vm.expectRevert(Nativo.WithdrawFailed.selector);
        nativo.withdrawAll();
    }

    function testWithdrawTo() public {
        vm.expectRevert(Nativo.AddressZero.selector);
        nativo.withdrawTo(address(0), 1);

        // nothing to burn
        vm.expectRevert(ERC20.InsufficientBalance.selector);
        nativo.withdrawTo(EOA, 1);

        nativo.deposit{value: 1}();

        vm.expectRevert(Nativo.WithdrawFailed.selector);
        nativo.withdrawTo(address(this), 1);

        vm.expectRevert(ERC20.InsufficientBalance.selector);
        nativo.withdrawTo(EOA, 2);
    }

    function testwithdrawFromTo() public {
        address bob = makeAddr("bob");

        vm.expectRevert(Nativo.AddressZero.selector);
        nativo.withdrawFromTo(EOA, address(0), 1);

        vm.expectRevert(stdError.arithmeticError);
        nativo.withdrawFromTo(EOA, bob, 1);

        vm.prank(EOA);
        nativo.approve(address(this), 1);

        // nothing to burn
        vm.expectRevert(ERC20.InsufficientBalance.selector);
        nativo.withdrawFromTo(EOA, bob, 1);

        nativo.depositTo{value: 1}(EOA);

        vm.expectRevert(Nativo.WithdrawFailed.selector);
        nativo.withdrawFromTo(EOA, address(this), 1);
    }

    function testPhantomFunction() public {
        bool success;
        (success,) = address(nativo).call{value: 1 ether}(abi.encodeWithSignature("thisShouldFail()"));
        assertFalse(success, "Should have reverted");

        (success,) = address(nativo).call("otherFunction");
        assertFalse(success, "Should have reverted");
    }

    function testManagerFunctions() public {
        vm.expectRevert("!manager");
        nativo.recoverERC20(makeAddr("token"), 1 ether);
        vm.expectRevert("!manager");
        nativo.recoverNativo(makeAddr("token"));

        vm.prank(manager);
        vm.expectRevert("Invalid account");
        nativo.recoverNativo(makeAddr("token"));
    }

    function testManagerSetter() public {
        vm.expectRevert("!manager");
        nativo.setManager(address(0));

        vm.expectRevert("!manager");
        nativo.setTreasury(address(0));

        vm.prank(manager);
        vm.expectRevert("!address(0)");
        nativo.setManager(address(0));

        vm.prank(manager);
        vm.expectRevert("!address(0)");
        nativo.setTreasury(address(0));
    }
}
