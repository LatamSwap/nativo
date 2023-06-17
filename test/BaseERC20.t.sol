// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/ERC/ERC20.sol";

contract Mock is ERC20("Mock", "MOCK") {
    function totalSupply() external view override returns (uint256) {
        return 0;
    }

    function mint(address to, uint256 amount) public {
        _mint(to, amount);
    }

    function burn(uint256 amount) public {
        _burn(msg.sender, amount);
    }

    function burnFrom(address from, uint256 amount) public {
        _spendAllowance(from, msg.sender, amount);
        _burn(from, amount);
    }

    function tr(address to, uint256 amount) public {
        _transfer(msg.sender, to, amount);
    }
}

contract Erc20Test is Test {
    Mock public token;

    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Approval(address indexed owner, address indexed spender, uint256 amount);

    function setUp() public {
        token = new Mock();
    }

    function testMint(uint256 toMint, uint256 toBurn) public {
        toBurn = bound(toBurn, 0, toMint);

        vm.expectEmit(true, true, true, true);
        emit Transfer(address(0), address(this), toMint);
        token.mint(address(this), toMint);
        assertEq(token.balanceOf(address(this)), toMint);

        vm.expectEmit(true, true, true, true);
        emit Transfer(address(this), address(0), toBurn);
        token.burn(toBurn);
        assertEq(token.balanceOf(address(this)), toMint - toBurn);
    }

    function testTransfer(address to, uint256 amount) public {
        token.mint(address(this), amount);

        vm.expectEmit(true, true, true, true);
        emit Transfer(address(this), to, amount);
        token.transfer(to, amount);
        if (to != address(this)) assertEq(token.balanceOf(address(this)), 0);
        assertEq(token.balanceOf(to), amount);
    }

    function testTransfer(address from, address to, uint256 amount) public {
        token.mint(from, amount);

        vm.expectEmit(true, true, true, true);
        emit Approval(from, address(this), amount);
        vm.prank(from);
        token.approve(address(this), amount);

        vm.expectEmit(true, true, true, true);
        emit Transfer(from, to, amount);
        token.transferFrom(from, to, amount);
        if (to != from) assertEq(token.balanceOf(from), 0);
        assertEq(token.balanceOf(to), amount);
    }

    function testInternalTransfer(address to, uint256 amount) public {
        token.mint(address(this), amount);

        vm.expectEmit(true, true, true, true);
        emit Transfer(address(this), to, amount);
        token.tr(to, amount);
        if (to != address(this)) assertEq(token.balanceOf(address(this)), 0);
        assertEq(token.balanceOf(to), amount);
    }

    function testBurnFrom() external {
        address eoa = makeAddr("EOA");

        vm.expectEmit(true, true, true, true);
        emit Transfer(address(0), eoa, 100);
        token.mint(eoa, 100);

        vm.expectEmit(true, true, true, true);
        emit Approval(eoa, address(this), 50);
        vm.prank(eoa);
        token.approve(address(this), 50);

        vm.expectEmit(true, true, true, true);
        emit Transfer(eoa, address(0), 20);
        token.burnFrom(eoa, 20);
        assertEq(token.balanceOf(eoa), 80);
        assertEq(token.allowance(eoa, address(this)), 30);
    
    }
}
