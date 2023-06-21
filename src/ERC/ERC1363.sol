// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.19;

import {ERC20} from "./ERC20.sol";

// import {IERC1363} from "openzeppelin/interfaces/IERC1363.sol";
import {IERC1363Spender} from "openzeppelin/interfaces/IERC1363Spender.sol";
import {IERC1363Receiver} from "openzeppelin/interfaces/IERC1363Receiver.sol";

/// @dev implementation of https://eips.ethereum.org/EIPS/eip-1363

abstract contract ERC1363 is ERC20 {
    function approveAndCall(address spender, uint256 amount) external returns (bool) {
        return approveAndCall(spender, amount, "");
    }

    function approveAndCall(address spender, uint256 amount, bytes memory data) public returns (bool) {
        _approve(msg.sender, spender, amount);
        bytes4 response = IERC1363Spender(spender).onApprovalReceived(msg.sender, amount, data);
        /*
         * 0x7b04a2d0 === bytes4(keccak256("onApprovalReceived(address,uint256,bytes)"))
         */
        require(response == 0x7b04a2d0, "IERC1363Spender: onApprovalReceived rejected");
        return true;
    }

    function transferAndCall(address to, uint256 amount) external returns (bool) {
        return transferAndCall(to, amount, "");
    }

    function transferAndCall(address to, uint256 amount, bytes memory data) public returns (bool) {
        _transfer(msg.sender, to, amount);
        bytes4 response = IERC1363Receiver(to).onTransferReceived(msg.sender, msg.sender, amount, data);
        // 0x88a7ca5c == `bytes4(keccak256("onTransferReceived(address,address,uint256,bytes)"))`
        require(response == 0x88a7ca5c, "IERC1363Receiver: onApprovalReceived rejected");
        return true;
    }

    function transferFromAndCall(address from, address to, uint256 amount) external returns (bool) {
        return transferFromAndCall(from, to, amount, "");
    }

    function transferFromAndCall(address from, address to, uint256 amount, bytes memory data) public returns (bool) {
        _spendAllowance(from, msg.sender, amount);
        _transfer(from, to, amount);
        bytes4 response = IERC1363Receiver(to).onTransferReceived(msg.sender, from, amount, data);
        // 0x88a7ca5c == `bytes4(keccak256("onTransferReceived(address,address,uint256,bytes)"))`
        require(response == 0x88a7ca5c, "IERC1363Receiver: onApprovalReceived rejected");
        return true;
    }

    // ERC165 interface support
    function supportsInterface(bytes4 interfaceId) external view returns (bool result) {
        /*
         * Note: the ERC-165 identifier for this interface is 0xb0202a11.
         * 0xb0202a11 ===
         *   bytes4(keccak256('transferAndCall(address,uint256)')) ^
         *   bytes4(keccak256('transferAndCall(address,uint256,bytes)')) ^
         *   bytes4(keccak256('transferFromAndCall(address,address,uint256)')) ^
         *   bytes4(keccak256('transferFromAndCall(address,address,uint256,bytes)')) ^
         *   bytes4(keccak256('approveAndCall(address,uint256)')) ^
         *   bytes4(keccak256('approveAndCall(address,uint256,bytes)'))
         */

        /// @solidity memory-safe-assembly
        assembly {
            let s := shr(224, interfaceId)
            // ERC1363: 0xb0202a11
            //result := or(eq(s, 0x.....), eq(s, 0x......))
            result := eq(s, 0xb0202a11)
        }
    }
}
