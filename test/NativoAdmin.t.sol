// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.10;

import "forge-std/Test.sol";

import {Nativo} from "src/Nativo.sol";
import {ERC20Mock} from "openzeppelin/mocks/ERC20Mock.sol";

contract NativoAdminTest is Test {
    Nativo public nativo;
    address public EOA = makeAddr("EOA");
    address public deployer = makeAddr("deployer");
    ERC20Mock public randomToken = new ERC20Mock();

    function setUp() public virtual {
        vm.roll(1);
        vm.warp(1);

        vm.prank(deployer);
        // name and symbol depend on the blockchain we are deploying
        nativo = new Nativo("Wrapped Native crypto", "wANY");
    }

    function testRecoverERC20() external {
        randomToken.mint(address(nativo), 10 ether);
        assertEq(randomToken.balanceOf(address(nativo)), 10 ether);

        vm.expectRevert();
        nativo.recoverERC20(address(randomToken), 10 ether);

        vm.prank(deployer);
        nativo.recoverERC20(address(randomToken), 10 ether);

        assertEq(randomToken.balanceOf(nativo.treasury()), 10 ether);

        deal(address(randomToken), address(nativo), 1 ether);
        assertEq(randomToken.balanceOf(address(nativo)), 1 ether);

        vm.prank(nativo.manager());
        nativo.recoverERC20(address(randomToken), 1 ether);
        assertEq(randomToken.balanceOf(nativo.treasury()), 11 ether);
    }

    function testRecoverERC20Nativo() external {
        // TODO recoverNativo
    }
}
