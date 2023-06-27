// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.10;

import "forge-std/Test.sol";

import {Nativo, ERC1363} from "src/Nativo.sol";
import {NFTtoken} from "./mock/NftMock.sol";

// Payable token tests
contract ERC1363Test is Test {
    Nativo public nativo;
    address public immutable EOA = makeAddr("EOA");
    address public immutable manager = makeAddr("managerAndTreasury");
    NFTtoken public nft;

    function setUp() public {
        vm.prank(manager);
        // name and symbol depend on the blockchain we are deploying
        nativo = new Nativo("Wrapped Nativo crypto", "nANY");
        nft = new NFTtoken(address(nativo), false);
    }

    function invariantMetadata() public {
        assertEq(nativo.name(), "Wrapped Nativo crypto", "Wrong name");
        assertEq(nativo.symbol(), "nANY", "Wrong symbol");
        assertEq(nativo.decimals(), 18, "Wrong decimals");
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

    function testReverts() public {
        nft = new NFTtoken(address(nativo), true);

        nativo.deposit{value: 1 ether}();
        vm.expectRevert(ERC1363.Receiver_transferReceived_rejected.selector);
        nativo.transferAndCall(address(nft), 0.5 ether);

        vm.expectRevert(ERC1363.Spender_onApprovalReceived_rejected.selector);
        nativo.approveAndCall(address(nft), 0.5 ether);
        
        nativo.transfer(EOA, 1 ether);
        vm.prank(EOA);
        nativo.approve(address(this), 1 ether);
        vm.expectRevert(ERC1363.Receiver_transferReceived_rejected.selector);
        nativo.transferFromAndCall(EOA, address(nft), 0.5 ether);

    }

    function testTransferAndCall() public {
        vm.deal(EOA, 1 ether);
        vm.startPrank(EOA);

        vm.expectRevert(abi.encodeWithSignature("InsufficientBalance()"));
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

    function testSupportsInterface() public {
        assertEq(nativo.supportsInterface(0xb0202a11), true);
        assertEq(nativo.supportsInterface(0xdeadbeef), false);
    }

    function testDepositTransferAndCall() public {
        nativo.depositTransferAndCall{value: 1 ether}(address(nft), 0.5 ether);
        assertEq(nft.balanceOf(address(this)), 1);
        assertEq(nativo.balanceOf(address(this)), 0.5 ether);
    }

    function testDepositTransferAndCallWithData() public {
        nativo.depositTransferAndCall{value: 1 ether}(address(nft), 0.5 ether, "");
        assertEq(nft.balanceOf(address(this)), 1);
        assertEq(nativo.balanceOf(address(this)), 0.5 ether);
    }
}
