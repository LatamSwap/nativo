// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.4;

interface INativo {
    error AddressZero();
    error AllowanceOverflow();
    error AllowanceUnderflow();
    error ERC3156ExceededMaxLoan(uint256 maxLoan);
    error ERC3156InvalidReceiver(address receiver);
    error ERC3156UnsupportedToken(address token);
    error InsufficientAllowance();
    error InsufficientBalance();
    error InvalidPermit();
    error PermitExpired();
    error WithdrawFailed();

    event Approval(address indexed owner, address indexed spender, uint256 amount);
    event RecoverNativo(address indexed account, uint256 amount);
    event Transfer(address indexed fxrom, address indexed to, uint256 amount);

    fallback() external payable;

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function allowance(address user, address spender) external view returns (uint256 amount);

    function approve(address spender, uint256 amount) external returns (bool);

    function approveAndCall(address spender, uint256 amount) external returns (bool);

    function approveAndCall(address spender, uint256 amount, bytes memory data) external returns (bool);

    function balanceOf(address account) external view returns (uint256 _balance);

    function decimals() external view returns (uint8);

    function deposit() external payable;

    function depositTo(address to) external payable;

    function flashFee(address token, uint256 amount) external view returns (uint256);

    function flashLoan(address receiver, address token, uint256 amount, bytes memory data) external returns (bool);

    function maxFlashLoan(address token) external view returns (uint256 maxLoan);

    function name() external view returns (string memory);

    function nonces(address user) external view returns (uint256 nonce);

    function permit(address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s)
        external;

    function recoverERC20(address token, uint256 amount) external;

    function recoverNativo(address account) external;

    function supportsInterface(bytes4 interfaceId) external view returns (bool result);

    function symbol() external view returns (string memory);

    function totalSupply() external view returns (uint256 totalSupply_);

    function transfer(address to, uint256 amount) external returns (bool);

    function transferAndCall(address to, uint256 amount) external returns (bool);

    function transferAndCall(address to, uint256 amount, bytes memory data) external returns (bool);

    function transferFrom(address from, address to, uint256 amount) external returns (bool);

    function transferFromAndCall(address from, address to, uint256 amount, bytes memory data) external returns (bool);

    function transferFromAndCall(address from, address to, uint256 amount) external returns (bool);

    function treasury() external view returns (address);

    function withdraw(uint256 amount) external;

    function withdrawFromTo(address from, address to, uint256 amount) external;

    function withdrawTo(address to, uint256 amount) external;

    receive() external payable;
}
