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
    address public constant treasury = 0x0000003FA6D1d52849db6E9EeC9d117FefA2e200;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(bytes32 name_, bytes32 symbol_) ERC20(name_, symbol_) {
        // extras?
        init_ERC3156();
    }

    /*//////////////////////////////////////////////////////////////
                               NATIVO LOGIC
    //////////////////////////////////////////////////////////////*/

    function deposit() external payable {
        // _mint(msg.sender, msg.value);
        assembly {
            sstore(caller(), add(sload(caller()), callvalue()))
        }
        emit Transfer(address(0), msg.sender, msg.value);
    }

    function depositTo(address to) external payable {
        // _mint(to, msg.value);
        assembly {
            sstore(to, add(sload(to), callvalue()))
        }
        emit Transfer(address(0), to, msg.value);
    }

    function withdraw(uint256 amount) external {
        // _burn(msg.sender, amount);
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

    function withdrawTo(address to, uint256 amount) external {
        // _burn(msg.sender, amount);
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
        emit Transfer(msg.sender, address(0), amount);
    }

    function withdrawFromTo(address from, address to, uint256 amount) external {
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

    receive() external payable {
        // _mint(msg.sender, msg.value);
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
        assembly {
            totalSupply_ := sub(add(selfbalance(), sload(_FLASH_MINTED_SLOT)), 0x01)
        }
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
        require(msg.sender == treasury, "!treasury");
        ERC20(token).transfer(treasury, amount);
    }

    function recoverNativo(address account) external {
        require(msg.sender == treasury, "!treasury");

        require(account <= address(uint160(uint256(0xdead))), "Invalid account");

        uint256 recoverAmount;
        /// @solidity memory-safe-assembly
        assembly {
            recoverAmount := sload(account)
            if iszero(recoverAmount) {
                mstore(0x00, 0x750b219c) // 0x750b219c = WithdrawFailed()
                revert(0x1c, 0x04)
            }
            sstore(account, 0)
            let treasuryBalance := sload(treasury)
            sstore(treasury, add(treasuryBalance, recoverAmount))
        }

        // tell that we recover some nativo from account
        emit RecoverNativo(account, recoverAmount);
    }
}
