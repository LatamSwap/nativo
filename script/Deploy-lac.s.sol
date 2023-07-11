// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.19;

import "forge-std/Script.sol";

import {Nativo} from "../src/Nativo.sol";

// deploy using
//
contract AvaxDeployScript is Script {
    function setUp() public {}
    // forge script script/Deploy-lac.s.sol --optimize --via-ir --optimizer-runs 20000  --rpc-url https://rpc1.mainnet.lachain.network --sender 0x0000003fa6d1d52849db6e9eec9d117fefa2e200

    function run() public returns (address nativoLAC) {
        vm.startBroadcast();
        // name and symbol depend on the blockchain we are deploying
        nativoLAC = address(new Nativo("Nativo Wrapped LAC", "nLAC", address(this), address(this)));
    }
}
