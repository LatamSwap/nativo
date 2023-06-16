// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {ERC20} from "./ERC20.sol";

contract Nativo is ERC20 {
    string private _name;
    string private _symbol;

    error WithdrawFailed();
    error AddressZero();

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
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
        if (to == address(0)) revert AddressZero();

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
        _transferEth(to, amount);
    }

    function withdrawFrom(address from, address to, uint256 amount) external {
        if (to == address(0)) revert AddressZero();

        _spendAllowance(from, msg.sender, amount);
        _burn(from, amount);
        _transferEth(to, amount);
    }

    function totalSupply() external view returns (uint256) {
        return address(this).balance;
    }

    function _transferEth(address to, uint256 amount) private {
        (bool sucess,) = to.call{value: amount}("");
        if (!sucess) revert WithdrawFailed();
    }
}
