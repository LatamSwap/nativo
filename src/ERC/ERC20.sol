// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.20;

import {StrHelper} from "../StrHelper.sol";

abstract contract ERC20 {
    // Balances of users will be stored onfrom 0x000000000000
    // reserve slots for balance storage
    // uint256[1 << 160] private __gapBalances;

    bytes32 private constant _PERMIT_SIGN =
        keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    bytes32 private constant _EIP712_DOMAIN =
        keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");

    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/

    /// @dev Insufficient balance. 4bytes sig 0xf4d678b8
    error InsufficientBalance();
    error PermitDeadlineExpired();
    error InvalidSigner();
    error InsufficientAllowance();

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed fxrom, address indexed to, uint256 amount);

    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /*//////////////////////////////////////////////////////////////
                            METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

    bytes32 private immutable _name;
    bytes32 private immutable _symbol;

    uint8 public constant decimals = 18;

    /*//////////////////////////////////////////////////////////////
                              ERC20 STORAGE
    //////////////////////////////////////////////////////////////*/
    // idea taken from https://github.com/Philogy/meth-weth/blob/5219af2f4ab6c91f8fac37b2633da35e20345a9e/src/reference/ReferenceMETH.sol
    struct Value {
        uint256 value;
    }
    
    /*//////////////////////////////////////////////////////////////
                            EIP-2612 STORAGE
    //////////////////////////////////////////////////////////////*/

    // @dev this is setted in a _NONCES_SLOT
    // uint256 private constant _NONCES_SLOT = uint256(keccak256(abi.encodePacked("nonces"))) - 1;
    // uint256 private constant _NONCES_SLOT = 0x9c054ed3b44e062c2512c7d33eb0c6bb551261bef4f17ca9367201ef0f7aa000;
    uint256 private constant _NONCES_SLOT = 0x9c054ed3b44e062c2512c7d33eb0c6bb551261bef4f17ca9367201ef0f7aa000;
    // mapping(address user => uint256 nonce) public nonces;

    uint256 internal immutable INITIAL_CHAIN_ID;

    bytes32 internal immutable INITIAL_DOMAIN_SEPARATOR;

    bytes32 internal immutable _NAME_KECCAK;
    bytes32 internal constant _VERSION_KECCAK = keccak256("1");

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(bytes32 name_, bytes32 symbol_) {
        _name = name_;
        _symbol = symbol_;

        INITIAL_CHAIN_ID = block.chainid;
        _NAME_KECCAK = keccak256(bytes(StrHelper.bytes32ToString(name_)));
        INITIAL_DOMAIN_SEPARATOR = computeDomainSeparator();
    }

    /*//////////////////////////////////////////////////////////////
                               ERC20 LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @dev Returns the name of the token.
    function name() external view returns (string memory) {
        return StrHelper.bytes32ToString(_name);
    }

    /// @dev Returns the symbol of the token.
    function symbol() external view returns (string memory) {
        return StrHelper.bytes32ToString(_symbol);
    }

    function allowance(address user, address spender) public returns (uint256) {
        return _allowance(user, spender).value;
    }

    function nonces() internal returns (mapping(address user => uint256 nonce) storage _nonces) {
        assembly {
            _nonces.slot := _NONCES_SLOT
        }
    }

    function nonces(address user) public returns (uint256 _nonce) {
        _nonce = nonces()[user];
    }

    function totalSupply() external view virtual returns (uint256);

    function balanceOf(address account) public view returns (uint256) {
        return _balanceOf(account).value;
    }
    
    function approve(address spender, uint256 amount) external returns (bool) {
        _allowance(msg.sender, spender).value = amount;

        emit Approval(msg.sender, spender, amount);

        return true;
    }

    function transfer(address to, uint256 amount) external returns (bool) {
        _transfer(msg.sender, to, amount);

        return true;
    }

    function transferFrom(address from, address to, uint256 amount) external returns (bool) {
        _useAllowance(from, amount);
        _transfer(from, to, amount);

        return true;
    }

    /*//////////////////////////////////////////////////////////////
                             EIP-2612 LOGIC
    //////////////////////////////////////////////////////////////*/

    function permit(address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s)
        external
    {
        if (deadline < block.timestamp) revert PermitDeadlineExpired();

        // Unchecked because the only math done is incrementing
        // the owner's nonce which cannot realistically overflow.
        unchecked {
            address recoveredAddress = ecrecover(
                keccak256(
                    abi.encodePacked(
                        "\x19\x01",
                        DOMAIN_SEPARATOR(),
                        keccak256(abi.encode(_PERMIT_SIGN, owner, spender, value, nonces()[owner]++, deadline))
                    )
                ),
                v,
                r,
                s
            );

            if (recoveredAddress == address(0) || recoveredAddress != owner) revert InvalidSigner();

            _allowance(recoveredAddress, spender).value = value;
        }

        emit Approval(owner, spender, value);
    }

    function DOMAIN_SEPARATOR() public view returns (bytes32) {
        return block.chainid == INITIAL_CHAIN_ID ? INITIAL_DOMAIN_SEPARATOR : computeDomainSeparator();
    }

    function computeDomainSeparator() internal view returns (bytes32) {
        return keccak256(abi.encode(_EIP712_DOMAIN, _NAME_KECCAK, _VERSION_KECCAK, block.chainid, address(this)));
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 amount) internal {
        unchecked {
            _balanceOf(to).value += amount;
        }

        emit Transfer(address(0), to, amount);
    }

    function _burn(address from, uint256 amount) internal {
        Value storage _balance = _balanceOf(from);
        
        if (_balance.value < amount) revert InsufficientBalance();

        unchecked {
            _balance.value = _balance.value - amount;
        }
        
        emit Transfer(from, address(0), amount);
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL HELPERS LOGIC
    //////////////////////////////////////////////////////////////*/

    function _approve(address owner, address spender, uint256 amount) internal {
        _allowance(owner, spender).value = amount;

        emit Approval(owner, spender, amount);
    }

    function _transfer(address from, address to, uint256 amount) internal {
        Value storage _balance = _balanceOf(from);

        if (_balance.value < amount) revert InsufficientBalance();

        unchecked {
            _balanceOf(from).value -= amount;
            _balanceOf(to).value += amount;
        }
        emit Transfer(from, to, amount);
    }

    // idea taken from https://github.com/Philogy/meth-weth/blob/5219af2f4ab6c91f8fac37b2633da35e20345a9e/src/reference/ReferenceMETH.sol
    function _balanceOf(address acc) internal pure returns (Value storage value) {
        /// @solidity memory-safe-assembly
        assembly {
            value.slot := acc
        }
    }

    // idea taken from https://github.com/Philogy/meth-weth/blob/5219af2f4ab6c91f8fac37b2633da35e20345a9e/src/reference/ReferenceMETH.sol
    function _allowance(address owner, address spender) internal pure returns (Value storage value) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, owner)
            mstore(0x20, spender)
            value.slot := keccak256(0x00, 0x40)
        }
    }

    // idea taken from https://github.com/Philogy/meth-weth/blob/5219af2f4ab6c91f8fac37b2633da35e20345a9e/src/reference/ReferenceMETH.sol
    function _useAllowance(address owner, uint256 amount) internal {
        Value storage currentAllowance = _allowance(owner, msg.sender);
        if(currentAllowance.value < amount) revert InsufficientAllowance();
        unchecked {
            // if msg.sender try to spend more than allowed it will do an arythmetic underflow revert
            if (currentAllowance.value != type(uint256).max) currentAllowance.value = currentAllowance.value - amount;
        }
    }
}