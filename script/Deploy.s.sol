// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.23;

import "forge-std/Script.sol";

import {Nativo} from "../src/Nativo.sol";
import {NativoDeployer} from "../src/Deployer.sol";

// deploy using
//
contract AvaxDeployScript is Script {
    function setUp() public {}
    // forge script script/Deploy.s.sol --optimize --via-ir --optimizer-runs 20000  --rpc-url https://rpc --sender 0x0000003fa6d1d52849db6e9eec9d117fefa2e200

    function run() public returns (address nativo) {
        address user = tx.origin;
        address CREATE2_FACTORY = 0x4e59b44847b379578588920cA78FbF26c0B4956C;
            
        vm.broadcast();
        (bool r, bytes memory data) = CREATE2_FACTORY.call(
            abi.encodePacked(
                keccak256("DEPLOYER"),
                abi.encodePacked(
                    type(NativoDeployer).creationCode,
                    abi.encode(user)
                )
            )
        );

        require(r, "CREATE2_FACTORY call failed");
        //address deployer = abi.decode(data, (address));
        address deployer = 0x77D4183E456c68a407056cad739DCF1AEaD77bbd;
        vm.broadcast();
        nativo = NativoDeployer(deployer).deploy(keccak256("demo"), 
            abi.encodePacked(
                type(Nativo).creationCode,
                abi.encode(bytes32("Nativo Wrapped ETH"), bytes32("nWETH"), address(this), address(this))
        ));
       
    }
}
