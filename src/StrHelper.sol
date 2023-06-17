// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library StrHelper {
    function bytes32ToString(bytes32 _bytes32) internal pure returns (string memory) {
        uint256 i;
        while (i < 32 && _bytes32[i] != 0) {
            i++;
        }
        bytes memory bytesArray = new bytes(i);
        for (i = 0; i < 32 && _bytes32[i] != 0; i++) {
            bytesArray[i] = _bytes32[i];
        }
        return string(bytesArray);
    }
}