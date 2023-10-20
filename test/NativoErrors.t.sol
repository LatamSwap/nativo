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
        nativo = new Nativo("Wrapped Nativo crypto", "wANY", manager, manager);
    }

    function testWithdraw() public {
        vm.expectRevert(ERC20.InsufficientBalance.selector);
        nativo.withdraw(1);

        // withdraw to address(this) should fail because
        // this contract doesn't have a fallback function

        nativo.deposit{value: 1}();
        vm.expectRevert(Nativo.ETHTransferFailed.selector);
        nativo.withdraw(1);

        vm.expectRevert(Nativo.ETHTransferFailed.selector);
        nativo.withdrawAll();
    }

    function testWithdrawTo() public {
        vm.expectRevert( /*Nativo.AddressZero.selector*/ );
        nativo.withdrawTo(address(0), 1);

        // nothing to burn
        vm.expectRevert( /*ERC20.InsufficientBalance.selector*/ );
        nativo.withdrawTo(EOA, 1);

        nativo.deposit{value: 1}();

        vm.expectRevert( /*Nativo.ETHTransferFailed.selector*/ );
        nativo.withdrawTo(address(this), 1);

        vm.expectRevert( /*ERC20.InsufficientBalance.selector*/ );
        nativo.withdrawTo(EOA, 2);
    }

    function testWithdrawFromTo() public {
        address bob = makeAddr("bob");

        vm.expectRevert();
        nativo.withdrawFromTo(EOA, address(0), 1);

        vm.expectRevert();
        nativo.withdrawFromTo(EOA, bob, 1);

        vm.prank(EOA);
        nativo.approve(address(this), 1);

        // nothing to burn
        vm.expectRevert( /*ERC20.InsufficientBalance.selector*/ );
        nativo.withdrawFromTo(EOA, bob, 1);

        nativo.depositTo{value: 1}(EOA);

        vm.expectRevert( /*Nativo.ETHTransferFailed.selector*/ );
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
        vm.expectRevert(Nativo.NotManager.selector);
        nativo.recoverERC20(makeAddr("token"), 1 ether);
        vm.expectRevert(Nativo.NotManager.selector);
        nativo.recoverNativo();
    }

    function testManagerSetter() public {
        vm.expectRevert(Nativo.NotManager.selector);
        nativo.setManager(address(0));

        vm.expectRevert(Nativo.NotManager.selector);
        nativo.setTreasury(address(0));

        vm.prank(manager);
        vm.expectRevert(Nativo.AddressZero.selector);
        nativo.setManager(address(0));

        vm.prank(manager);
        vm.expectRevert(Nativo.AddressZero.selector);
        nativo.setTreasury(address(0));
    }

    function testDontCollisionWithBalances(address from, address spender, uint256 amount) public {
        vm.prank(from);
        vm.record();
        nativo.approve(spender, amount);
        (bytes32[] memory reads, bytes32[] memory writes) = vm.accesses(address(nativo));
        assertGt(uint256(writes[0]), type(uint160).max);
    }
}
