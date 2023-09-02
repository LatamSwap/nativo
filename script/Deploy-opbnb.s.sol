// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.20;

import "forge-std/Script.sol";

import {Nativo} from "../src/Nativo.sol";

// deploy using
//
contract OpbnbDeployScript is Script {
    function setUp() public {}
    // forge script script/Deploy-scroll.s.sol --optimize --optimizer-runs 20000  --rpc-url https://opbnb-testnet-rpc.bnbchain.org --sender 0x0000003fa6d1d52849db6e9eec9d117fefa2e200 --verify

    function run() public returns (address nativoETH) {
        vm.startBroadcast();
        // name and symbol depend on the blockchain we are deploying
        nativoETH = address(new Nativo("Nativo Wrapped opBNB", "ntBNB", address(this), address(this)));
    }
}
// https://opbnb-testnet.bscscan.com 

// forge verify-contract 0xff6ae961405b4f3e3169e6640cd1ca3083d58a7b src/Nativo.sol:Nativo --optimizer-runs=20000
