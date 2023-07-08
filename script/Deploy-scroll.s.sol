// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.19;

import "forge-std/Script.sol";

import {Nativo} from "../src/Nativo.sol";

// deploy using
//
contract AvaxDeployScript is Script {
    function setUp() public {}
    // forge script script/Deploy-scroll.s.sol --optimize --optimizer-runs 20000  --rpc-url https://scroll-alphanet.public.blastapi.io --sender 0x0000003fa6d1d52849db6e9eec9d117fefa2e200 --verify

    function run() public returns (address nativoETH) {
        vm.startBroadcast();
        // name and symbol depend on the blockchain we are deploying
        nativoETH = address(new Nativo("Nativo Wrapped ETH", "nETH"));
    }
}

// forge verify-contract 0x2Ca416EA2F4bb26ff448823EB38e533b60875C81 src/Nativo.sol:Nativo --chain-id=10200 --optimizer-runs=20000