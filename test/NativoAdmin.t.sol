// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.10;

import "forge-std/Test.sol";

import {Nativo} from "src/Nativo.sol";
import {ERC20Mock} from "openzeppelin/mocks/token/ERC20Mock.sol";

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
        nativo = new Nativo("Wrapped Nativo crypto", "wANY", deployer, deployer);
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
        nativo.deposit{value: 0.5 ether}();
        nativo.transfer(address(0), 0.5 ether);
        nativo.depositTo{value: 0.5 ether}(address(0));
        nativo.depositTo{value: 0.5 ether}(address(0xdead));

        vm.expectRevert();
        nativo.recoverNativo();

        assertEq(nativo.balanceOf(address(0)), 1 ether);

        vm.prank(deployer);
        nativo.recoverNativo();
        assertEq(nativo.balanceOf(nativo.treasury()), 1.5 ether);

        vm.prank(deployer);
        nativo.recoverNativo();
        assertEq(nativo.balanceOf(nativo.treasury()), 1.5 ether);

        assertEq(nativo.balanceOf(nativo.treasury()), 1.5 ether);
    }

    function testChangeTreasury() external {
        nativo.depositTo{value: 0.5 ether}(address(0));

        vm.prank(deployer);
        nativo.recoverNativo();

        address newTreasury = makeAddr("newTreasury");
        vm.expectRevert();
        nativo.setTreasury(newTreasury);

        vm.prank(deployer);
        vm.expectRevert();
        nativo.setTreasury(address(0));

        vm.prank(deployer);
        nativo.setTreasury(newTreasury);

        nativo.depositTo{value: 0.5 ether}(address(0));

        vm.prank(deployer);
        nativo.recoverNativo();

        assertEq(nativo.balanceOf(newTreasury), 0.5 ether);
    }

    function testSetManager() external {
        vm.prank(deployer);
        vm.expectRevert();
        nativo.setManager(address(0));

        address newManager = makeAddr("newManager");
        vm.expectRevert();
        nativo.setManager(newManager);

        vm.prank(deployer);
        nativo.setManager(newManager);

        vm.prank(deployer);
        vm.expectRevert();
        nativo.setManager(newManager);
    }
}
