// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {ERC20} from "./ERC/ERC20.sol";
import {ERC3156} from "./ERC/ERC3156.sol";
import {ERC1363} from "./ERC/ERC1363.sol";

import {SafeTransferLib} from "solmate/utils/SafeTransferLib.sol";

contract Nativo is ERC20, ERC3156, ERC1363 {
    string private _name;
    string private _symbol;

    // @dev this is the treasury address, where the fees will be sent
    // this address will be define later, for now we use a arbitrary address
    address public constant treasury = 0x00000000fFFffDB6Fc1F34ac4aD25dd9eF7031eF;

    error WithdrawFailed();
    error AddressZero();

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    function _flashFeeReceiver() internal override view returns (address) {
        return treasury;
    }

    /// @dev Returns the name of the token.
    function name() public view override returns (string memory) {
        return _name;
    }

    /// @dev Returns the symbol of the token.
    function symbol() public view override returns (string memory) {
        return _symbol;
    }

    fallback() external payable {
        // @dev this is to avoid certain issues, like the anyswap incident with the erc20permit call
        revert("Method not found");
    }

    receive() external payable {
        _mint(msg.sender, msg.value);
    }

    function deposit() external payable {
        _mint(msg.sender, msg.value);
    }

    function depositTo(address to) external payable {
        _mint(to, msg.value);
    }

    function withdraw(uint256 amount) public {
        _burn(msg.sender, amount);

        // if we use function _transferEth this will be more expenseive
        // because it will need an extra variable to store msg.sender
        (bool sucess,) = msg.sender.call{value: amount}("");
        if (!sucess) revert WithdrawFailed();
    }

    function withdrawTo(address to, uint256 amount) external {
        if (to == address(0)) revert AddressZero();

        _burn(msg.sender, amount);
        SafeTransferLib.safeTransferETH(to, amount);
    }

    function withdrawFrom(address from, address to, uint256 amount) external {
        if (to == address(0)) revert AddressZero();

        _spendAllowance(from, msg.sender, amount);
        _burn(from, amount);
        SafeTransferLib.safeTransferETH(to, amount);
    }

    function totalSupply() external view returns (uint256) {
        return address(this).balance + 1 - _flashMinted;
    }

}
