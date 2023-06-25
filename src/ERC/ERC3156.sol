// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.19;

import {ERC20} from "./ERC20.sol";

import {IERC3156FlashBorrower} from "openzeppelin/interfaces/IERC3156FlashBorrower.sol";
import {IERC3156FlashLender} from "openzeppelin/interfaces/IERC3156FlashLender.sol";

// @dev implementation of https://eips.ethereum.org/EIPS/eip-3156

abstract contract ERC3156 is ERC20, IERC3156FlashLender {
    // @dev _FLASH_MINTED_SLOT = uint256(keccak256("ERC3156_FLASHMINTED")) - 1;
    uint256 internal constant _FLASH_MINTED_SLOT = 0x3965801a1a161db0d5a8d326fe0135e2586f55ca7bc4e22ea49399d97c657530;

    bytes32 private constant _RETURN_VALUE = keccak256("ERC3156FlashBorrower.onFlashLoan");
    uint256 private constant _FEE_BPS = 100_00; // 100%
    uint256 private constant _FEE = 9; // 0.09%

    /**
     * @dev The loan token is not valid.
     */
    error ERC3156UnsupportedToken(address token);

    /**
     * @dev The requested loan exceeds the max loan amount for `token`.
     */
    error ERC3156ExceededMaxLoan(uint256 maxLoan);

    /**
     * @dev The receiver of a flashloan is not a valid {onFlashLoan} implementer.
     */
    error ERC3156InvalidReceiver(address receiver);

    function init_ERC3156() internal {
        assert(_FLASH_MINTED_SLOT == uint256(keccak256("ERC3156_FLASHMINTED")) - 1);
        require(_flashMinted() == 0, "ERC3156: already initialized");
        assembly {
            // @dev flashMinted is used to keep track of the amount of tokens minted in a flash loan
            //      is starting in 1 to save gas
            sstore(_FLASH_MINTED_SLOT, 1)
        }
    }

    function _flashMinted() internal view returns (uint256 flashMinted) {
        assembly {
            flashMinted := sload(_FLASH_MINTED_SLOT)
        }
    }

    function _maxFlashLoan() private view returns (uint256 ret) {
        assembly {
            // -1 is because _flashMinted is starting in 1
            ret := sub(sload(_FLASH_MINTED_SLOT), 0x01)
        }
        ret = address(this).balance - ret;
    }

    /**
     * @dev Returns the maximum amount of tokens available for loan.
     * @param token The address of the token that is requested.
     * @return maxLoan The amount of token that can be loaned.
     */
    function maxFlashLoan(address token) public view returns (uint256 maxLoan) {
        if (token != address(this)) {
            // @dev if user want a different token than LAC or WLAC will reverte
            revert ERC3156UnsupportedToken(token);
        }
        maxLoan = _maxFlashLoan();
    }

    /**
     * @dev Returns the fee applied when doing flash loans. By default this
     * is set to 0.09% (9 bips).
     * @param token The token to be flash loaned.
     * @param amount The amount of tokens to be loaned.
     * @return fee The fees applied to the corresponding flash loan.
     */
    function flashFee(address token, uint256 amount) external view returns (uint256 fee) {
        if (token != address(this)) {
            revert ERC3156UnsupportedToken(token);
        }
        // @dev fixed fee of 0.09%
        assembly {
            fee := div(mul(amount, _FEE), _FEE_BPS)
        }
    }

    /**
     * @dev Returns the receiver address of the flash fee. By default this
     * implementation returns the address(0) which means the fee amount will be burnt.
     * This function can be overloaded to change the fee receiver.
     * @return The address for which the flash fee will be sent to.
     */
    function _flashFeeReceiver() internal view virtual returns (address);

    /**
     * @dev Performs a flash loan. New tokens are minted and sent to the
     * `receiver`, who is required to implement the {IERC3156FlashBorrower}
     * interface. By the end of the flash loan, the receiver is expected to own
     * amount + fee tokens and have them approved back to the token contract itself so
     * they can be burned.
     * @param receiver The receiver of the flash loan. Should implement the
     * {IERC3156FlashBorrower-onFlashLoan} interface.
     * @param token The token to be flash loaned. Only `address(this)` is
     * supported.
     * @param amount The amount of tokens to be loaned.
     * @param data An arbitrary datafield that is passed to the receiver.
     * @return `true` if the flash loan was successful.
     */
    // This function can reenter, but it doesn't pose a risk because it always preserves the property that the amount
    // minted at the beginning is always recovered and burned at the end, or else the entire function will revert.
    // slither-disable-next-line reentrancy-no-eth
    function flashLoan(IERC3156FlashBorrower receiver, address token, uint256 amount, bytes calldata data)
        external
        returns (bool)
    {
        uint256 flashMinted = _flashMinted();
        if (flashMinted > 1) revert("ERC3156: reentrancy not allowed");
        if (amount < 10000) revert("ERC3156: min amount is 1000 wei");

        if (token != address(this)) {
            revert ERC3156UnsupportedToken(token);
        }

        uint256 maxLoan = _maxFlashLoan();
        if (amount > maxLoan) {
            revert ERC3156ExceededMaxLoan(maxLoan);
        }

        // update flashMinted amount
        assembly {
            sstore(_FLASH_MINTED_SLOT, add(flashMinted, amount))
        }

        // @dev fee is 0,09%
        uint256 fee;
        assembly {
            fee := div(mul(amount, _FEE), _FEE_BPS)
        }

        _mint(address(receiver), amount);
        if (receiver.onFlashLoan(msg.sender, token, amount, fee, data) != _RETURN_VALUE) {
            revert ERC3156InvalidReceiver(address(receiver));
        }

        // reset flashMinted amount
        assembly {
            sstore(_FLASH_MINTED_SLOT, 0x01)
        }

        _spendAllowance(address(receiver), address(this), amount + fee);
        _burn(address(receiver), amount);
        _transfer(address(receiver), _flashFeeReceiver(), fee);
        return true;
    }
}
