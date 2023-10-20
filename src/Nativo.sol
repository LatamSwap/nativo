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

import {SafeTransferLib} from "solady/utils/SafeTransferLib.sol";

/**
 * @title Nativo
 * @dev Nativo is an enhanced version of the WETH contract, which provides
 * a way to wrap the native cryptocurrency of any supported EVM network into
 * an ERC20 token, thus enabling more sophisticated interaction with smart
 * contracts and DApps on various blockchains.
 */
contract Nativo is ERC20, ERC1363, ERC3156 {
    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/

    error ETHTransferFailed();
    error AddressZero();
    error NotImplemented();
    error NotManager();

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event SetTreasury(address oldManager, address newManager);
    event SetManager(address oldTreasury, address newTreasury);

    /*//////////////////////////////////////////////////////////////
                            METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

    // @dev this is the treasury address, where the fees will be sent
    // uint256 private constant _TREASURY_SLOT = uint256(keccak256("nativo.treasury")) - 1;
    uint256 private constant _TREASURY_SLOT = 0xb76b8f07153e093af01f73b720adfb99ea2070ca7e3105f7c8fea3b5ab75663a;

    // uint256 private constant _MANAGER_SLOT = uint256(keccak256("nativo.manager")) - 1;
    uint256 private constant _MANAGER_SLOT = 0x709669ee5c3ce7b0e78e55c2f47250d0b6830456b94cb9ed5e645a7dd423b1a4;

    function treasury() public view returns (address treasury_) {
        /// @solidity memory-safe-assembly
        assembly {
            treasury_ := sload(_TREASURY_SLOT)
        }
    }

    function manager() public view returns (address manager_) {
        /// @solidity memory-safe-assembly
        assembly {
            manager_ := sload(_MANAGER_SLOT)
        }
    }

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(bytes32 name_, bytes32 symbol_, address _treasury, address _manager) ERC20(name_, symbol_) {
        init_ERC3156();
        assembly {
            // store address of treasury
            sstore(_TREASURY_SLOT, _treasury)
            // store address of manager
            sstore(_MANAGER_SLOT, _manager)
        }
    }

    /*//////////////////////////////////////////////////////////////
                               NATIVO LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @notice Deposit native currency to get Nativo tokens
    /// @dev This function is payable and will mint Nativo tokens, using the `msg.sender`
    ///      address as the slot position to store the balance.
    function deposit() external payable {
        _mint(msg.sender, msg.value);
    }

    /// @notice Deposit native currency to get Nativo tokens in `to` address
    /// @dev This function is payable and will mint Nativo tokens, using the `to`
    ///      address as the slot position to store the balance.
    function depositTo(address to) external payable {
        _mint(to, msg.value);
    }

    /// @notice Withdraw native currency burning `amount` of Nativo tokens
    /// @param amount The amount of Nativo tokens to burn
    function withdraw(uint256 amount) public {
        _burn(msg.sender, amount);
        _transferETH(msg.sender, amount);
    }

    /// @notice Withdraw all native currency of `msg.sender`,  burning all Nativo tokens owned by `msg.sender`
    function withdrawAll() external {
        withdraw(_balanceOf(msg.sender).value);
    }

    /// @notice Withdraw native currency burning `amount` of Nativo tokens and send it to `to` address
    /// @param to The address to send the native currency
    /// @param amount The amount of Nativo tokens to burn
    function withdrawTo(address to, uint256 amount) public {
        _burn(msg.sender, amount);
        _transferETH(to, amount);
    }

    /// @notice Withdraw all native currency of `msg.sender`,  burning all Nativo tokens owned by `msg.sender` and send it to `to` address
    /// @param to The address to send the native currency
    function withdrawAllTo(address to) external {
        withdrawTo(to, _balanceOf(msg.sender).value);
    }

    function withdrawFromTo(address from, address to, uint256 amount) public {
        // @dev decrease allowance (if not have unlimited allowance)
        _useAllowance(from, amount);
        _burn(from, amount);
        _transferETH(to, amount);
    }

    function withdrawAllFromTo(address from, address to) external {
        withdrawFromTo(from, to, balanceOf(from));
    }

    receive() external payable {
        _mint(msg.sender, msg.value);
    }

    fallback() external payable {
        revert NotImplemented();
    }

    function _transferETH(address to, uint256 amount) internal {
        if (to == address(0)) revert AddressZero();
        SafeTransferLib.safeTransferETH(to, amount);
    }

    /*//////////////////////////////////////////////////////////////
                               ERC20 LOGIC
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev totalSupply is the total amount of Native currency in contract (example ETH) plus
     *     the amount of Nativo tokens minted in flash loans, minus one, because the
     *     flash loan will always be (1+flashMinted), please review the ERC3156.sol
     */
    function totalSupply() external view override returns (uint256 totalSupply_) {
        /// @solidity memory-safe-assembly
        assembly {
            totalSupply_ := sub(add(selfbalance(), sload(_FLASH_MINTED_SLOT)), 0x01)
        }
    }

    /*//////////////////////////////////////////////////////////////
                               ERC3156 LOGIC
    //////////////////////////////////////////////////////////////*/

    function _flashFeeReceiver() internal view override returns (address) {
        return treasury();
    }

    /*//////////////////////////////////////////////////////////////
                       PROTOCOL RECOVER LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @notice Recover ERC20 token sent to the contract, even Nativo
    function recoverERC20(address token, uint256 amount) external {
        if (msg.sender != manager()) revert NotManager();
        SafeTransferLib.safeTransfer(token, treasury(), amount);
    }

    /// @notice Recover nativo ERC20 token sent to dead address: address(0) or address(0xdead)
    /// @dev Nativo ERC20 token sent to dead address are consider donations and should be claimable by the protocol
    function recoverNativo() external {
        if (msg.sender != manager()) revert NotManager();

        // dead address and zero address are consider donation address
        _recover(address(0));
        _recover(address(0xdead));
    }

    function _recover(address lossAddress) private {
        // @dev get balance of loss address
        Value storage _lossBal = _balanceOf(lossAddress);

        // @dev if loss address have balance, send it to treasury
        if (_lossBal.value > 0) {
            _transfer(lossAddress, treasury(), _lossBal.value);
        }
    }

    /*//////////////////////////////////////////////////////////////
                       PROTOCOL ADDRESS MANAGEMENT
    //////////////////////////////////////////////////////////////*/

    function setManager(address account) external {
        if (msg.sender != manager()) revert NotManager();
        if (account == address(0)) revert AddressZero();

        assembly {
            sstore(_MANAGER_SLOT, account)
        }
        emit SetManager(msg.sender, account);
    }

    function setTreasury(address newTreasury) external {
        if (msg.sender != manager()) revert NotManager();
        if (newTreasury == address(0)) revert AddressZero();

        address oldTreasury;
        assembly {
            oldTreasury := sload(_TREASURY_SLOT)
            sstore(_TREASURY_SLOT, newTreasury)
        }
        emit SetTreasury(oldTreasury, newTreasury);
    }
}
