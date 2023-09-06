// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.10;

import "forge-std/Test.sol";

import {Nativo, ERC1363} from "src/Nativo.sol";
import {NFTtoken} from "../mock/NftMock.sol";

// Payable token tests
contract GasERC1363Test is Test {
    Nativo public nativo;
    address public immutable EOA = makeAddr("EOA");
    address public immutable manager = makeAddr("managerAndTreasury");
    NFTtoken public nft;

    function setUp() public {
        vm.prank(manager);
        // name and symbol depend on the blockchain we are deploying
        nativo = new Nativo("Wrapped Nativo crypto", "nANY", manager, manager);
        nft = new NFTtoken(address(nativo), false);

        vm.deal(EOA, 1 ether);
        vm.prank(EOA);
        nativo.deposit{value: 1 ether}();
    }

    function test_Gas_ApproveAndCall() public {
        vm.prank(EOA);
        nativo.approveAndCall(address(nft), 0.5 ether);
    }

    function test_Gas_TransferAndCall() public {
        vm.prank(EOA);
        nativo.transferAndCall(address(nft), 0.5 ether);
    }

    function test_Gas_TransferFromAndCall() public {
        vm.prank(EOA);
        nativo.approve(address(this), 0.6 ether);

        nativo.transferFromAndCall(EOA, address(nft), 0.5 ether);
    }

    function test_Gas_DepositTransferAndCall() public {
        nativo.depositTransferAndCall{value: 1 ether}(address(nft), 0.5 ether);
    }

    function test_Gas_DepositTransferAndCallWithData() public {
        nativo.depositTransferAndCall{value: 1 ether}(address(nft), 0.5 ether, "");
    }
}
