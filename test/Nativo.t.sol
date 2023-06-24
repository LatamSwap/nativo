// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.10;

import "forge-std/Test.sol";

import {Nativo, ERC20} from "src/Nativo.sol";

contract NativoTest is Test {
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

    function invariantMetadata() public {
        assertEq(nativo.name(), "Wrapped Nativo crypto", "Wrong name");
        assertEq(nativo.symbol(), "wANY", "Wrong symbol");
        assertEq(nativo.decimals(), 18, "Wrong decimals");
    }

    function testPhantomFunction() public {
        bool success;
        (success,) = address(nativo).call{value: 1 ether}("!implemented");
        assertFalse(success, "Should have reverted");

        (success,) = address(nativo).call("otherFunction");
        assertFalse(success, "Should have reverted");
    }

    function testCantWithdraw() external {
        bool success;
        (success,) = address(nativo).call{value: 0.5 ether}("");
        assertTrue(success, "Should have success");
        (success,) = address(nativo).call{value: 0.5 ether}("");
        assertTrue(success, "Should have success");

        assertEq(address(nativo).balance, 1 ether, "Wrong balance");
        assertEq(nativo.totalSupply(), 1 ether, "Wrong total supply");
        assertEq(nativo.balanceOf(address(this)), 1 ether, "Wrong balance of user");

        // contract cant receive ether, doesnt have a fallback function
        vm.expectRevert(Nativo.WithdrawFailed.selector);
        nativo.withdraw(0.5 ether);

        // contract cant receive ether, doesnt have a fallback function
        vm.expectRevert(Nativo.WithdrawFailed.selector);
        nativo.withdrawTo(address(this), 0.5 ether);

        vm.expectRevert(Nativo.AddressZero.selector);
        nativo.withdrawTo(address(0), 0.5 ether);

        nativo.withdrawTo(address(0xc0ffe), 0.5 ether);

        vm.expectRevert(ERC20.InsufficientBalance.selector);
        nativo.withdrawTo(address(0xc0ffe), 1.5 ether);
    }

    function testDepositTo(address from, address to, uint256 amount) public {
        vm.assume(from != address(0));
        vm.deal(from, amount);
        vm.prank(from);

        nativo.depositTo{value: amount}(to);
        assertEq(nativo.balanceOf(to), amount);
    }

    function testDepositAndWithdraw(uint256 amount, uint256 remove, uint256 remove2, address removeTo) public {
        amount = bound(amount, 1, type(uint128).max);
        remove = bound(remove, 0, amount);
        remove2 = bound(remove2, 0, amount - remove);

        // console contract = 0x000000000000000000636F6e736F6c652e6c6f67
        vm.assume(removeTo != 0x000000000000000000636F6e736F6c652e6c6f67);
        // avoid precompiled contracts
        vm.assume(removeTo > address(0x100));
        // if removeTo is a contract and doesnt have a receive function, this will fail, to we skip this for now
        vm.assume(removeTo.code.length == 0x00);

        vm.deal(EOA, amount);

        vm.startPrank(EOA);
        assertEq(EOA.balance, amount);
        nativo.deposit{value: amount}();
        assertEq(nativo.totalSupply(), amount);

        nativo.withdraw(remove);

        assertEq(nativo.totalSupply(), amount - remove);
        assertEq(EOA.balance, remove);

        vm.expectRevert();
        nativo.withdraw(amount + 1);

        if (remove2 > nativo.balanceOf(EOA) || removeTo == address(0) || removeTo == address(nativo)) {
            vm.expectRevert();
            nativo.withdrawTo(removeTo, remove2);
        } else {
            uint256 balanceBeforeWithdraw = removeTo.balance;
            nativo.withdrawTo(removeTo, remove2);

            assertEq(nativo.totalSupply(), amount - remove - remove2);
            assertEq(removeTo.balance, balanceBeforeWithdraw + remove2);
        }

        vm.stopPrank();
    }

    function testDepositAndWithdrawAll(uint256 amount, address removeTo) public {
        amount = bound(amount, 1, type(uint128).max);

        // console contract = 0x000000000000000000636F6e736F6c652e6c6f67
        vm.assume(removeTo != 0x000000000000000000636F6e736F6c652e6c6f67);
        // avoid precompiled contracts
        vm.assume(removeTo > address(0x100));
        // if removeTo is a contract and doesnt have a receive function, this will fail, to we skip this for now
        vm.assume(removeTo.code.length == 0x00);

        vm.deal(EOA, amount);

        vm.startPrank(EOA);
        assertEq(EOA.balance, amount);
        nativo.deposit{value: amount}();
        assertEq(nativo.totalSupply(), amount);

        nativo.withdrawAll();

        assertEq(nativo.totalSupply(), 0);
        assertEq(EOA.balance, amount);

        vm.stopPrank();
    }

    function testWithdrawTo() public {
        vm.expectRevert();
        nativo.withdrawTo(address(0), 1);
        vm.expectRevert();
        nativo.withdrawTo(address(nativo), 1);

        // nothing to burn
        vm.expectRevert();
        nativo.withdrawTo(EOA, 1);

        vm.expectRevert();
        nativo.withdrawTo(address(this), 1);

        nativo.deposit{value: 10}();

        vm.expectRevert();
        nativo.withdrawTo(address(this), 1);

        nativo.withdrawTo(EOA, 1);
        assertEq(EOA.balance, 1);

        nativo.transfer(EOA, 2);
        vm.startPrank(EOA);
        vm.expectRevert();
        nativo.withdrawTo(address(this), 1);
        address bob = makeAddr("bob");
        nativo.withdrawTo(bob, 1);
        assertEq(bob.balance, 1);

        // widthdraw to self
        nativo.withdrawTo(EOA, 1);
        assertEq(EOA.balance, 2);
        assertEq(nativo.balanceOf(EOA), 0);
        vm.stopPrank();
    }

    function testWithdrawAllFromTo() public {
        nativo.deposit{value: 10}();

        vm.expectRevert();
        nativo.withdrawAllFromTo(EOA, address(this));

        nativo.depositTo{value: 1}(EOA);
        vm.prank(EOA);
        nativo.approve(EOA, 1);

        vm.prank(EOA);
        nativo.withdrawAllFromTo(EOA, EOA);
        assertEq(EOA.balance, 1);

        nativo.transfer(EOA, 2);

        address bob = makeAddr("bob");

        vm.prank(EOA);
        vm.expectRevert();
        nativo.withdrawAllFromTo(EOA, address(this));

        vm.prank(EOA);
        nativo.approve(address(this), 1);

        vm.expectRevert();
        nativo.withdrawAllFromTo(EOA, bob);

        vm.prank(EOA);
        nativo.approve(address(this), 2);

        assertEq(nativo.allowance(EOA, address(this)), 2);
        nativo.withdrawAllFromTo(EOA, bob);

        assertEq(bob.balance, 2);
        assertEq(nativo.allowance(EOA, address(this)), 0);
    }

    function withdrawAllTo() public {
        nativo.withdrawAllTo(address(0xc0ffe));

        assertEq(nativo.balanceOf(address(0xc0ffe)), 0);

        vm.expectRevert();
        nativo.withdrawAllTo(address(0));

        nativo.deposit{value: 1 ether}();

        vm.expectRevert();
        nativo.withdrawAllTo(address(0));

        nativo.withdrawAllTo(address(0xc0ffe));

        assertEq(nativo.balanceOf(address(0xc0ffe)), 1 ether);
    }

    function testwithdrawFromTo() public {
        vm.expectRevert();
        nativo.withdrawFromTo(EOA, address(0), 1);
        vm.expectRevert();
        nativo.withdrawFromTo(EOA, address(nativo), 1);

        // nothing to burn
        vm.expectRevert();
        nativo.withdrawFromTo(EOA, EOA, 1);

        vm.expectRevert();
        nativo.withdrawFromTo(EOA, address(this), 1);

        nativo.deposit{value: 10}();

        vm.expectRevert();
        nativo.withdrawFromTo(EOA, address(this), 1);

        nativo.depositTo{value: 1}(EOA);
        vm.prank(EOA);
        nativo.approve(EOA, 1);

        vm.prank(EOA);
        nativo.withdrawFromTo(EOA, EOA, 1);
        assertEq(EOA.balance, 1);

        nativo.transfer(EOA, 2);

        address bob = makeAddr("bob");

        vm.prank(EOA);
        vm.expectRevert();
        nativo.withdrawFromTo(EOA, address(this), 1);

        vm.prank(EOA);
        nativo.approve(address(this), 1);

        vm.expectRevert();
        nativo.withdrawFromTo(EOA, bob, 10);

        nativo.withdrawFromTo(EOA, bob, 1);

        assertEq(bob.balance, 1);
    }
}
