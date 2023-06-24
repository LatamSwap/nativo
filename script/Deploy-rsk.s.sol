// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.19;

import "forge-std/Script.sol";

import {Nativo} from "../src/Nativo.sol";

// deploy using
//
contract AvaxDeployScript is Script {
    function setUp() public {}
    // forge script script/Deploy-rsk.s.sol --optimize --via-ir --optimizer-runs 20000 --verify --retries=10 --rpc-url https://public-node.testnet.rsk.co --sender 0x0000003fa6d1d52849db6e9eec9d117fefa2e200

    function run() public returns (address nativoRSK) {
        vm.startBroadcast();
        // name and symbol depend on the blockchain we are deploying
        nativoRSK = address(new Nativo("Nativo RSK Smart Bitcoin", "nRBTC"));
    }
}
