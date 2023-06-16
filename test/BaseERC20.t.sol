// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/ERC20.sol";

contract Mock is ERC20 {
    function name() public pure override returns (string memory) {
        return "Mock";
    }

    function symbol() public pure override returns (string memory) {
        return "MOCK";
    }

    function mint(address to, uint256 amount) public {
        _mint(to, amount);
    }

    function burn(address from, uint256 amount) public {
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
        token.burn(address(this), toBurn);
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
}
