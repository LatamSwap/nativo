// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.10;

import "forge-std/Test.sol";

import {Nativo} from "src/Nativo.sol";
import {NFTtoken} from "./mock/NftMock.sol";

// Payable token tests
contract ERC1363Test is Test {
    Nativo public nativo;
    address public immutable EOA = makeAddr("EOA");
    NFTtoken public nft;

    function setUp() public {
        // name and symbol depend on the blockchain we are deploying
        nativo = new Nativo("Wrapped Nativo crypto", "nANY");
        nft = new NFTtoken(address(nativo));
    }

    function testApproveAndCall() public {
        vm.deal(EOA, 1 ether);
        vm.startPrank(EOA);

        vm.expectRevert();
        nativo.approveAndCall(address(nft), 1 ether);
        assertEq(nativo.allowance(EOA, address(nft)), 0);

        nativo.deposit{value: 1 ether}();

        vm.expectRevert("Send 0.5 ether");
        nativo.approveAndCall(address(nft), 1 ether);

        nativo.approveAndCall(address(nft), 0.5 ether);

        assertEq(nft.balanceOf(EOA), 1);

        vm.stopPrank();
    }

    function testTransferAndCall() public {
        vm.deal(EOA, 1 ether);
        vm.startPrank(EOA);

        vm.expectRevert();
        nativo.transferAndCall(address(nft), 1 ether);
        assertEq(nativo.allowance(EOA, address(nft)), 0);

        nativo.deposit{value: 1 ether}();

        vm.expectRevert("Send 0.5 ether");
        nativo.transferAndCall(address(nft), 1 ether);

        nativo.transferAndCall(address(nft), 0.5 ether);

        assertEq(nft.balanceOf(EOA), 1);

        vm.stopPrank();
    }

    function testTransferFromAndCall() public {
        vm.deal(EOA, 1 ether);

        // transferFromAndCall(address from, address to, uint256 amount, bytes memory data)

        vm.expectRevert();
        nativo.transferFromAndCall(EOA, address(nft), 1 ether);
        assertEq(nativo.allowance(EOA, address(nft)), 0);

        vm.prank(EOA);
        nativo.deposit{value: 1 ether}();

        vm.expectRevert();
        nativo.transferFromAndCall(EOA, address(nft), 0.5 ether);

        vm.prank(EOA);
        nativo.approve(address(this), 0.6 ether);

        vm.expectRevert();
        nativo.transferFromAndCall(EOA, address(nft), 0.6 ether);

        nativo.transferFromAndCall(EOA, address(nft), 0.5 ether);
        assertEq(nativo.allowance(EOA, address(this)), 0.1 ether);

        assertEq(nft.balanceOf(EOA), 1);
    }
}
