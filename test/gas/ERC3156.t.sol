// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.10;

import "forge-std/Test.sol";

import {Nativo} from "src/Nativo.sol";
import {ERC3156BorrowerMock} from "../mock/BorrowerMock.sol";

// FLASHLOAN tests
contract ERC3156Test is Test {
    Nativo public nativo;
    address public immutable EOA = makeAddr("EOA");
    address public immutable manager = makeAddr("manager");
    address treasury = makeAddr("treasury");
    ERC3156BorrowerMock receiver;

    function setUp() public {
        vm.prank(manager);
        // name and symbol depend on the blockchain we are deploying
        nativo = new Nativo("Wrapped Nativo crypto", "nANY", manager, manager);

        vm.prank(manager);
        nativo.setTreasury(treasury);
        receiver = new ERC3156BorrowerMock(true, true);
    }

    function test_Gas_FlashLoanSuccess() public {
        nativo.deposit{value: 10009}();

        // 1 token to pay the fee
        nativo.transfer(address(receiver), 9);
        nativo.flashLoan(receiver, address(nativo), 10000, "");
    }
}
