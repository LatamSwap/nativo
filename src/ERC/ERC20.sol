// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.19;

abstract contract ERC20 {
    // Balances of users will be stored onfrom 0x000000000000
    // reserve slots for balance storage
    uint256[1 << 160] private __gapBalances;

    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/

    /// @dev Insufficient balance. 4bytes sig 0xf4d678b8
    error InsufficientBalance();

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed fxrom, address indexed to, uint256 amount);

    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /*//////////////////////////////////////////////////////////////
                            METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

    string public name;
    string public symbol;

    uint8 public constant decimals = 18;

    /*//////////////////////////////////////////////////////////////
                              ERC20 STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(address user => mapping(address spender => uint256 amount)) public allowance;

    /*//////////////////////////////////////////////////////////////
                            EIP-2612 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 internal immutable INITIAL_CHAIN_ID;

    bytes32 internal immutable INITIAL_DOMAIN_SEPARATOR;

    mapping(address user => uint256 nonce) public nonces;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(string memory name_, string memory symbol_) {
        name = name_;
        symbol = symbol_;

        INITIAL_CHAIN_ID = block.chainid;
        INITIAL_DOMAIN_SEPARATOR = computeDomainSeparator();
    }

    /*//////////////////////////////////////////////////////////////
                               ERC20 LOGIC
    //////////////////////////////////////////////////////////////*/

    function totalSupply() external view virtual returns (uint256);

    function balanceOf(address account) public view returns (uint256 _balance) {
        /// @solidity memory-safe-assembly
        assembly {
            _balance := sload(account)
        }
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        allowance[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);

        return true;
    }

    function transfer(address to, uint256 amount) external returns (bool) {
        uint256 _balance;

        /// @solidity memory-safe-assembly
        assembly {
            _balance := sload(caller())
        }
        if (_balance < amount) revert InsufficientBalance();

        /// @solidity memory-safe-assembly
        assembly {
            // cant underflow due previous check
            // unchecked { balanceOf[msg.sender] -= amount; }
            sstore(caller(), sub(_balance, amount))

            // Cannot overflow because the sum of all user
            // balances can't exceed the max uint256 value.
            // unchecked {
            //    balanceOf[to] += amount;
            // }
            sstore(to, add(sload(to), amount))
        }

        emit Transfer(msg.sender, to, amount);

        return true;
    }

    function transferFrom(address from, address to, uint256 amount) external returns (bool) {
        uint256 allowed = allowance[from][msg.sender]; // Saves gas for limited approvals.

        // if msg.sender try to spend more than allowed it will do an arythmetic underflow revert
        if (allowed != type(uint256).max) allowance[from][msg.sender] = allowed - amount;

        _transfer(from, to, amount);

        return true;
    }

    /*//////////////////////////////////////////////////////////////
                             EIP-2612 LOGIC
    //////////////////////////////////////////////////////////////*/

    function permit(address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s)
        external
    {
        require(deadline >= block.timestamp, "PERMIT_DEADLINE_EXPIRED");

        // Unchecked because the only math done is incrementing
        // the owner's nonce which cannot realistically overflow.
        unchecked {
            address recoveredAddress = ecrecover(
                keccak256(
                    abi.encodePacked(
                        "\x19\x01",
                        DOMAIN_SEPARATOR(),
                        keccak256(
                            abi.encode(
                                keccak256(
                                    "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
                                ),
                                owner,
                                spender,
                                value,
                                nonces[owner]++,
                                deadline
                            )
                        )
                    )
                ),
                v,
                r,
                s
            );

            require(recoveredAddress != address(0) && recoveredAddress == owner, "INVALID_SIGNER");

            allowance[recoveredAddress][spender] = value;
        }

        emit Approval(owner, spender, value);
    }

    function DOMAIN_SEPARATOR() public view returns (bytes32) {
        return block.chainid == INITIAL_CHAIN_ID ? INITIAL_DOMAIN_SEPARATOR : computeDomainSeparator();
    }

    function computeDomainSeparator() internal view returns (bytes32) {
        return keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256(bytes(name)),
                keccak256("1"),
                block.chainid,
                address(this)
            )
        );
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 amount) internal {
        /// @solidity memory-safe-assembly
        assembly {
            // Cannot overflow because the sum of all user
            // balances can't exceed the max uint256 value.
            // unchecked {
            //    balanceOf[to] += amount;
            // }
            sstore(to, add(sload(to), amount))
        }

        emit Transfer(address(0), to, amount);
    }

    function _burn(address from, uint256 amount) internal {
        uint256 _balance;
        /// @solidity memory-safe-assembly
        assembly {
            _balance := sload(from)
        }

        if (_balance < amount) revert InsufficientBalance();

        /// @solidity memory-safe-assembly
        assembly {
            // balanceOf[from] -= amount;
            // cant underflow due previous checks
            sstore(from, sub(_balance, amount))
        }

        emit Transfer(from, address(0), amount);
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL HELPERS LOGIC
    //////////////////////////////////////////////////////////////*/

    function _approve(address owner, address spender, uint256 amount) internal {
        allowance[owner][spender] = amount;

        emit Approval(owner, spender, amount);
    }

    function _spendAllowance(address owner, address spender, uint256 amount) internal {
        uint256 allowed = allowance[owner][spender]; // Saves gas for limited approvals.

        // if spender try to spend more than allowed it will do an arythmetic underflow revert
        if (allowed != type(uint256).max) allowance[owner][spender] = allowed - amount;
    }

    function _transfer(address from, address to, uint256 amount) internal {
        uint256 _balance;
        /// @solidity memory-safe-assembly
        assembly {
            _balance := sload(from)
        }

        if (_balance < amount) revert InsufficientBalance();

        assembly {
            // cant underflow due previous check
            // balanceOf[from] -= amount;
            sstore(from, sub(_balance, amount))

            // Cannot overflow because the sum of all user
            // balances can't exceed the max uint256 value.
            // unchecked {
            //     balanceOf[to] += amount;
            // }
            sstore(to, add(sload(to), amount))
        }
        emit Transfer(from, to, amount);
    }
}
