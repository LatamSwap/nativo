// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.10;

import "forge-std/Test.sol";

import {Nativo} from "src/Nativo.sol";

// FLASHLOAN tests
contract ERC3156Test is Test {
    Nativo public nativo;
    address public immutable EOA = makeAddr("EOA");

    function setUp() public {
        // name and symbol depend on the blockchain we are deploying
        nativo = new Nativo("Wrapped Native crypto", "wANY");
    }
}
