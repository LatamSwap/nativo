// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.19;

import "forge-std/Script.sol";

import {Nativo} from "../src/Nativo.sol";

// deploy using
// forge script script/Deploy-avax-fuji.s.sol --optimize --via-ir --optimizer-runs 20000 --verify --retries=10 --etherscan-api-key T9 --rpc-url https://endpoints.omniatech.io/v1/avax/fuji/public

contract AvaxDeployScript is Script {
    function setUp() public {}

    function run() public returns (address nativoAvax) {
        vm.startBroadcast();
        // name and symbol depend on the blockchain we are deploying
        nativoAvax = address(new Nativo("Nativo Wrapped Avax", "nAVAX"));
    }
}
