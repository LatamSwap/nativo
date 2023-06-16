// SPDX-License-Identifier: MIT
pragma solidity >=0.8.10;

import "forge-std/Test.sol";

import {Nativo} from "src/Nativo.sol";

contract NativoTest is Test {
    Nativo public nativo;
    address EOA = makeAddr("EOA");

    function setUp() public virtual {
        vm.roll(1);
        vm.warp(1);

        // name and symbol depend on the blockchain we are deploying
        nativo = new Nativo("Wrapped Natice crytpo", "Wany");
    }

    function testMetadata() public {
        assertEq(nativo.name(), "Wrapped Natice crytpo", "Wrong name");
        assertEq(nativo.symbol(), "Wany", "Wrong symbol");
        assertEq(nativo.decimals(), 18, "Wrong decimals");
    }

    function testDepositTo(address from, address to, uint256 amount) public {
        vm.assume(from != address(0));
        vm.deal(from, amount);
        vm.prank(from);

        if (to == address(0)) {
            vm.expectRevert();
            nativo.depositTo{value: amount}(to);
        } else {
            nativo.depositTo{value: amount}(to);
            assertEq(nativo.balanceOf(to), amount);
        }
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

    function testWithdrawFrom() public {
        vm.expectRevert();
        nativo.withdrawFrom(EOA, address(0), 1);
        vm.expectRevert();
        nativo.withdrawFrom(EOA, address(nativo), 1);

        // nothing to burn
        vm.expectRevert();
        nativo.withdrawFrom(EOA, EOA, 1);

        vm.expectRevert();
        nativo.withdrawFrom(EOA, address(this), 1);

        nativo.deposit{value: 10}();

        vm.expectRevert();
        nativo.withdrawFrom(EOA, address(this), 1);

        nativo.depositTo{value: 1}(EOA);
        vm.prank(EOA);
        nativo.approve(EOA, 1);

        vm.prank(EOA);
        nativo.withdrawFrom(EOA, EOA, 1);
        assertEq(EOA.balance, 1);

        nativo.transfer(EOA, 2);

        address bob = makeAddr("bob");

        vm.prank(EOA);
        vm.expectRevert();
        nativo.withdrawFrom(EOA, address(this), 1);

        vm.prank(EOA);
        nativo.approve(address(this), 1);

        vm.expectRevert();
        nativo.withdrawFrom(EOA, bob, 10);

        nativo.withdrawFrom(EOA, bob, 1);

        assertEq(bob.balance, 1);
    }
}