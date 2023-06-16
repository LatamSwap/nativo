// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {ERC20} from "./ERC/ERC20.sol";
import {ERC3156} from "./ERC/ERC3156.sol";
import {ERC1363} from "./ERC/ERC1363.sol";

import {SafeTransferLib} from "solmate/utils/SafeTransferLib.sol";

contract Nativo is ERC20, ERC3156, ERC1363 {
    bytes32 immutable _name;
    bytes32 immutable _symbol;

    // @dev this is the treasury address, where the fees will be sent
    // this address will be define later, for now we use a arbitrary address
    address public constant treasury = 0x00000000fFFffDB6Fc1F34ac4aD25dd9eF7031eF;

    error WithdrawFailed();
    error AddressZero();

    constructor(bytes32 name_, bytes32 symbol_) {
        _name = name_;
        _symbol = symbol_;
        
        init_ERC3156();
    }

    function _flashFeeReceiver() internal view override returns (address) {
        return treasury;
    }

    /// @dev Returns the name of the token.
    function name() public view override returns (string memory) {
        return bytes32ToString(_name);
    }

    /// @dev Returns the symbol of the token.
    function symbol() public view override returns (string memory) {
        return bytes32ToString(_symbol);
    }

    function bytes32ToString(bytes32 _bytes32) internal pure returns (string memory) {
        uint256 i;
        while(i < 32 && _bytes32[i] != 0) {
            i++;
        }
        bytes memory bytesArray = new bytes(i);
        for (i = 0; i < 32 && _bytes32[i] != 0; i++) {
            bytesArray[i] = _bytes32[i];
        }
        return string(bytesArray);
    }

    fallback() external payable {
        // @dev this is to avoid certain issues, like the anyswap incident with the erc20permit call
        revert("Method not found");
    }

    receive() external payable {
        // _mint(msg.sender, msg.value);
        /// @dev this is cheaper, avoiding extra variable for callvalue() and caller()
        /// @solidity memory-safe-assembly
        assembly {
            // Compute the balance slot and load its value.
            // let toBalanceSlot := caller()
            // Add and store the updated balance.
            sstore(caller(), add(sload(caller()), callvalue()))
            // Emit the {Transfer} event.
            mstore(0x20, callvalue())
            log3(0x20, 0x20, _TRANSFER_EVENT_SIGNATURE, 0, caller())
        }
    }


    function recoverERC20(address token, uint256 amount) public {
        require(token != address(this), "Cannot recover nativo");
        require(msg.sender == treasury, "!treasury");
        ERC20(token).transfer(treasury, amount);
    }

    function recoverNativo(address account) external {
        require(msg.sender == treasury, "!treasury");

        require(account == address(this) || account <= address(uint160(uint256(0xdead))), "Invalid account");

        uint256 recoverAmount;
        /// @solidity memory-safe-assembly
        assembly {
            account := shr(96, shl(96, account))
            recoverAmount := sload(account)
            sstore(account, 0)
            let treasuryBalance := sload(treasury)
            sstore(treasury, add(treasuryBalance, recoverAmount))
        }

        // tell that we recover some nativo from account
        emit RecoverNativo(account, recoverAmount);
    }
    event RecoverNativo(address indexed account, uint256 amount);

    function deposit() external payable {
        // _mint(msg.sender, msg.value);
        /// @dev this is cheaper, avoiding extra variable for callvalue() and caller()
        /// @solidity memory-safe-assembly
        assembly {
            // Compute the balance slot and load its value.
            //let toBalanceSlot := caller()
            // Add and store the updated balance.
            sstore(caller(), add(sload(caller()), callvalue()))
            // Emit the {Transfer} event.
            mstore(0x20, callvalue())
            log3(0x20, 0x20, _TRANSFER_EVENT_SIGNATURE, 0, caller())
        }
    }

    function depositTo(address to) external payable {
        // _mint(to, msg.value);
        /// @dev this is cheaper, avoiding extra variable for callvalue() and caller()
        /// @solidity memory-safe-assembly
        assembly {
            // clean `to`
            to := shr(96, shl(96, to))
            // Compute the balance slot and load its value.
            // let toBalanceSlot := or(_BALANCE_SLOT_MASK, to)
            // Add and store the updated balance.
            sstore(to, add(sload(to), callvalue()))
            // Emit the {Transfer} event.
            mstore(0x20, callvalue())
            log3(0x20, 0x20, _TRANSFER_EVENT_SIGNATURE, 0, to)
        }
    }

    function withdraw(uint256 amount) public {
        /// @solidity memory-safe-assembly
        assembly {
            // Compute the balance slot and load its value.
            let fromBalance := sload(caller())
            // Revert if insufficient balance.
            if gt(amount, fromBalance) {
                mstore(0x00, 0xf4d678b8) // `InsufficientBalance()`.
                revert(0x1c, 0x04)
            }
            // Subtract and store the updated balance.
            sstore(caller(), sub(fromBalance, amount))
            // Emit the {Transfer} event.
            mstore(0x00, amount)
            log3(0x00, 0x20, _TRANSFER_EVENT_SIGNATURE, caller(), 0)
        }

        // if we use function transferEth func this will be more expensive
        // because it will need an extra variable to store msg.sender
        bool success;

        /// @solidity memory-safe-assembly
        assembly {
            // Transfer the ETH and store if it succeeded or not.
            success := call(gas(), caller(), amount, 0, 0, 0, 0)
        }
        if (!success) revert WithdrawFailed();
    }

    function withdrawTo(address to, uint256 amount) external {
        if (to == address(0)) revert AddressZero();

        /// @solidity memory-safe-assembly
        assembly {
            // Compute the balance slot and load its value.
            let fromBalance := sload(caller())
            // Revert if insufficient balance.
            if gt(amount, fromBalance) {
                mstore(0x00, 0xf4d678b8) // `InsufficientBalance()`.
                revert(0x1c, 0x04)
            }
            // Subtract and store the updated balance.
            sstore(caller(), sub(fromBalance, amount))
            // Emit the {Transfer} event.
            mstore(0x00, amount)
            log3(0x00, 0x20, _TRANSFER_EVENT_SIGNATURE, caller(), 0)
        }
        SafeTransferLib.safeTransferETH(to, amount);
    }

    function withdrawFrom(address from, address to, uint256 amount) external {
        if (to == address(0)) revert AddressZero();

        // _spendAllowance(from, msg.sender, amount);
        /// @solidity memory-safe-assembly
        assembly {
            // Compute the allowance slot and load its value.
            mstore(0x20, caller())
            mstore(0x0c, _ALLOWANCE_SLOT_SEED)
            mstore(0x00, from)
            let allowanceSlot := keccak256(0x0c, 0x34)
            let allowance_ := sload(allowanceSlot)
            // If the allowance is not the maximum uint256 value.
            if iszero(eq(allowance_, not(0))) {
                // Revert if the amount to be transferred exceeds the allowance.
                if gt(amount, allowance_) {
                    mstore(0x00, 0x13be252b) // `InsufficientAllowance()`.
                    revert(0x1c, 0x04)
                }
                // Subtract and store the updated allowance.
                sstore(allowanceSlot, sub(allowance_, amount))
            }
        }

        _burn(from, amount);
        SafeTransferLib.safeTransferETH(to, amount);
    }

    function totalSupply() external view returns (uint256 totalSupply_) {
        assembly{
            totalSupply_ := sub(
                add(selfbalance(), sload(_FLASH_MINTED_SLOT)),
                0x01
            )
        }
    }
}
