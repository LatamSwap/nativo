// SPDX-License-Identifier: BUSL-1.1

/// @title A title that should describe the contract/interface
/// @author eugenioclrc & rotcivegaf
/// @notice Nativo is an enhanced version of the WETH contract, which provides
/// a way to wrap the native cryptocurrency of any supported EVM network into
/// an ERC20 token, thus enabling more sophisticated interaction with smart
/// contracts and DApps on various blockchains.

pragma solidity 0.8.20;

import {ERC20} from "./ERC/ERC20.sol";
import {ERC1363} from "./ERC/ERC1363.sol";
import {ERC3156} from "./ERC/ERC3156.sol";

contract Nativo is ERC20, ERC1363, ERC3156 {
    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/

    error WithdrawFailed();
    error AddressZero();

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event RecoverNativo(address indexed account, uint256 amount);

    /*//////////////////////////////////////////////////////////////
                            METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

    // @dev this is the treasury address, where the fees will be sent
    // this address will be define later, for now we use a arbitrary address
    address public treasury = 0x0000003FA6D1d52849db6E9EeC9d117FefA2e200;
    address public manager;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(bytes32 name_, bytes32 symbol_) ERC20(name_, symbol_) {
        // extras?
        init_ERC3156();
        manager = msg.sender;
    }

    /*//////////////////////////////////////////////////////////////
                               NATIVO LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @notice Deposit native currency to get Nativo tokens
    /// @dev This function is payable and will mint Nativo tokens, using the `msg.sender`
    ///      address as the slot position to store the balance.
    function deposit() external payable {
        // _mint(msg.sender, msg.value);
        /// @solidity memory-safe-assembly
        assembly {
            sstore(caller(), add(sload(caller()), callvalue()))
        }
        emit Transfer(address(0), msg.sender, msg.value);
    }

    /// @notice Deposit native currency to get Nativo tokens in `to` address
    /// @dev This function is payable and will mint Nativo tokens, using the `to`
    ///      address as the slot position to store the balance.
    function depositTo(address to) external payable {
        // _mint(to, msg.value);
        /// @solidity memory-safe-assembly
        assembly {
            sstore(to, add(sload(to), callvalue()))
        }
        emit Transfer(address(0), to, msg.value);
    }

    /// @notice Withdraw native currency burning `amount` of Nativo tokens
    /// @param amount The amount of Nativo tokens to burn
    function withdraw(uint256 amount) public {
        // _burn(msg.sender, amount);
        /// @solidity memory-safe-assembly
        assembly {
            let _balance := sload(caller())
            if lt(_balance, amount) {
                mstore(0x00, 0xf4d678b8) // 0xf4d678b8 = InsufficientBalance()
                revert(0x1c, 0x04)
            }
            sstore(caller(), sub(_balance, amount))

            // Transfer the ETH and store if it succeeded or not.
            let success := call(gas(), caller(), amount, 0, 0, 0, 0)
            if iszero(success) {
                mstore(0x00, 0x750b219c) // 0x750b219c = WithdrawFailed()
                revert(0x1c, 0x04)
            }
        }
        emit Transfer(msg.sender, address(0), amount);
    }

    /// @notice Withdraw all native currency of `msg.sender`,  burning all Nativo tokens owned by `msg.sender`
    function withdrawAll() external {
        withdraw(balanceOf(msg.sender));
    }

    /// @notice Withdraw native currency burning `amount` of Nativo tokens and send it to `to` address
    /// @param to The address to send the native currency
    /// @param amount The amount of Nativo tokens to burn
    function withdrawTo(address to, uint256 amount) public {
        // _burn(msg.sender, amount);
        /// @solidity memory-safe-assembly
        assembly {
            // if (to == address(0)) revert AddressZero();
            if iszero(to) {
                mstore(0x00, 0x750b219c) // 0x9fabe1c1 = AddressZero()
                revert(0x1c, 0x04)
            }
            // if (amount > balanceOf(msg.sender)) revert InsufficientBalance();
            let _balance := sload(caller())
            if lt(_balance, amount) {
                mstore(0x00, 0xf4d678b8) // 0xf4d678b8 = InsufficientBalance()
                revert(0x1c, 0x04)
            }
            sstore(caller(), sub(_balance, amount))

            // Transfer the ETH and store if it succeeded or not.
            let success := call(gas(), to, amount, 0, 0, 0, 0)
            if iszero(success) {
                mstore(0x00, 0x750b219c) // 0x750b219c = WithdrawFailed()
                revert(0x1c, 0x04)
            }
        }

        emit Transfer(msg.sender, to, amount);
        emit Transfer(to, address(0), amount);
    }

    /// @notice Withdraw all native currency of `msg.sender`,  burning all Nativo tokens owned by `msg.sender` and send it to `to` address
    /// @param to The address to send the native currency
    function withdrawAllTo(address to) external {
        withdrawTo(to, balanceOf(msg.sender));
    }

    function withdrawFromTo(address from, address to, uint256 amount) public {
        /// @solidity memory-safe-assembly
        assembly {
            // if (to == address(0)) revert AddressZero();
            if iszero(to) {
                mstore(0x00, 0x750b219c) // 0x9fabe1c1 = AddressZero()
                revert(0x1c, 0x04)
            }
        }

        // @dev decrease allowance (if not have unlimited allowance)
        uint256 allowed = allowance[from][msg.sender]; // Saves gas for limited approvals.
        if (allowed != type(uint256).max) allowance[from][msg.sender] = allowed - amount;

        /// @solidity memory-safe-assembly
        assembly {
            sstore(from, sub(sload(from), amount))

            // Transfer the ETH and store if it succeeded or not.
            let success := call(gas(), to, amount, 0, 0, 0, 0)
            if iszero(success) {
                mstore(0x00, 0x750b219c) // 0x750b219c = WithdrawFailed()
                revert(0x1c, 0x04)
            }
        }

        // transfer to
        emit Transfer(from, to, amount);
        // now burn event
        emit Transfer(to, address(0), amount);
    }

    function withdrawAllFromTo(address from, address to) external {
        withdrawFromTo(from, to, balanceOf(from));
    }

    receive() external payable {
        // _mint(msg.sender, msg.value);
        /// @solidity memory-safe-assembly
        assembly {
            sstore(caller(), add(sload(caller()), callvalue()))
        }
        emit Transfer(address(0), msg.sender, msg.value);
    }

    fallback() external payable {
        revert("!implemented");
    }

    /*//////////////////////////////////////////////////////////////
                               ERC20 LOGIC
    //////////////////////////////////////////////////////////////*/

    function totalSupply() external view override returns (uint256 totalSupply_) {
        /// @solidity memory-safe-assembly
        assembly {
            totalSupply_ := sub(add(selfbalance(), sload(_FLASH_MINTED_SLOT)), 0x01)
        }
    }

    /*//////////////////////////////////////////////////////////////
                            EXTRA ERC1363 LOGIC
    //////////////////////////////////////////////////////////////*/

    function depositTransferAndCall(address to, uint256 amount) external payable returns (bool) {
        // _mint(msg.sender, msg.value);
        /// @solidity memory-safe-assembly
        assembly {
            sstore(caller(), add(sload(caller()), callvalue()))
        }
        emit Transfer(address(0), msg.sender, msg.value);

        return transferAndCall(to, amount, "");
    }

    function depositTransferAndCall(address to, uint256 amount, bytes memory data) external payable returns (bool) {
        // _mint(msg.sender, msg.value);

        /// @solidity memory-safe-assembly
        assembly {
            sstore(caller(), add(sload(caller()), callvalue()))
        }
        emit Transfer(address(0), msg.sender, msg.value);

        return transferAndCall(to, amount, data);
    }

    /*//////////////////////////////////////////////////////////////
                               ERC3156 LOGIC
    //////////////////////////////////////////////////////////////*/

    function _flashFeeReceiver() internal view override returns (address) {
        return treasury;
    }

    /*//////////////////////////////////////////////////////////////
                       PROTOCOL RECOVER LOGIC
    //////////////////////////////////////////////////////////////*/

    function recoverERC20(address token, uint256 amount) public {
        require(msg.sender == manager, "!manager");
        ERC20(token).transfer(treasury, amount);
    }

    function recoverNativo(address account) external {
        require(msg.sender == manager, "!manager");

        // dead address or zero address are consider donation address
        require(account == address(0) || account == address(0xdead), "Invalid account");

        uint256 recoverAmount;
        address _treasury = treasury;
        /// @solidity memory-safe-assembly
        assembly {
            recoverAmount := sload(account)
            if iszero(recoverAmount) {
                mstore(0x00, 0x750b219c) // 0x750b219c = WithdrawFailed()
                revert(0x1c, 0x04)
            }
            sstore(account, 0)
            let treasuryBalance := sload(_treasury)
            sstore(_treasury, add(treasuryBalance, recoverAmount))
        }

        // tell that we recover some nativo from account
        emit RecoverNativo(account, recoverAmount);
    }

    /*//////////////////////////////////////////////////////////////
                       PROTOCOL ADDRESS MANAGMENT
    //////////////////////////////////////////////////////////////*/

    function setManager(address account) external {
        require(msg.sender == manager, "!manager");
        require(account != address(0), "Invalid account");
        manager = account;
    }

    function setTreasury(address newTreasury) external {
        require(msg.sender == manager, "!manager");
        require(newTreasury != address(0), "Invalid newTreasury");
        treasury = newTreasury;
    }
}
