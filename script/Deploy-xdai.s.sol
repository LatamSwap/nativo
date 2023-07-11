// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.19;

import "forge-std/Script.sol";

import {Nativo} from "../src/Nativo.sol";

// deploy using
//
contract AvaxDeployScript is Script {
    function setUp() public {}
    // forge script script/Deploy-xdai.s.sol --optimize --optimizer-runs 20000  --rpc-url https://rpc.chiadochain.net --sender 0x0000003fa6d1d52849db6e9eec9d117fefa2e200

    function run() public returns (address nativoXDAI) {
        vm.startBroadcast();
        // name and symbol depend on the blockchain we are deploying
        nativoXDAI = address(new Nativo("Nativo Wrapped XDAI", "nXDAI", address(this), address(this)));
    }
}

// forge verify-contract 0x2A955Cd173b851bac5Be79BdC8Cbc5D5a30e1d8d src/Nativo.sol:Nativo  --verifier blockscout --chain-id=10200 --optimizer-runs=20000
