// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.23;

import {CREATE3} from "solady/utils/CREATE3.sol";
import {Ownable} from "solady/auth/Ownable.sol";

// this contract will be deployed using CREATE2, and then will deploy the Nativo contract
contract NativoDeployer is Ownable {
    constructor (address _owner){
        _initializeOwner(_owner);
    }

    function deploy(bytes32 salt, bytes memory initCode) external onlyOwner payable returns (address) {
        return CREATE3.deploy(salt, initCode, msg.value);
    }

    function predict(bytes32 salt) public returns (address) {
        return CREATE3.getDeployed(salt);
    }
}
