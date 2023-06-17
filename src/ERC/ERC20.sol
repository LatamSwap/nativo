// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {StrHelper} from "../StrHelper.sol";

abstract contract ERC20 {
    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/

    /// @dev The allowance has overflowed.
    error AllowanceOverflow();

    /// @dev The allowance has underflowed.
    error AllowanceUnderflow();

    /// @dev Insufficient balance. 4bytes sig 0xf4d678b8
    error InsufficientBalance();

    /// @dev Insufficient allowance.
    error InsufficientAllowance();

    /// @dev The permit is invalid.
    error InvalidPermit();

    /// @dev The permit has expired.
    error PermitExpired();

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed fxrom, address indexed to, uint256 amount);

    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /*//////////////////////////////////////////////////////////////
                            METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

    bytes32 immutable _name;
    bytes32 immutable _symbol;

    uint8 public constant decimals = 18;

    /*//////////////////////////////////////////////////////////////
                              ERC20 STORAGE
    //////////////////////////////////////////////////////////////*/

    // Balances of users will be stored onfrom 0x000000000000

    mapping(address => mapping(address => uint256)) public allowance;

    /*//////////////////////////////////////////////////////////////
                            EIP-2612 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 internal immutable INITIAL_CHAIN_ID;

    bytes32 internal immutable INITIAL_DOMAIN_SEPARATOR;

    mapping(address => uint256) public nonces;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(bytes32 name_, bytes32 symbol_) {
        _name = name_;
        _symbol = symbol_;

        INITIAL_CHAIN_ID = block.chainid;
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

    function totalSupply() external view virtual returns (uint256);

    function balanceOf(address account) external view returns (uint256 _balance) {
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
        assembly {
            // balanceOf[msg.sender] -= amount;
            let _balance := sload(caller())
            if lt(_balance, amount) {
                mstore(0x00, 0x13be252b) // TODO calcular keccak `InsufficientAllowance()`.
                revert(0x1c, 0x04)
            }
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

        if (allowed != type(uint256).max) allowance[from][msg.sender] = allowed - amount;

        _transfer(from, to, amount);

        return true;
    }

    /*//////////////////////////////////////////////////////////////
                             EIP-2612 LOGIC
    //////////////////////////////////////////////////////////////*/

    function permit(address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s)
        public
        virtual
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

    function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
        return block.chainid == INITIAL_CHAIN_ID ? INITIAL_DOMAIN_SEPARATOR : computeDomainSeparator();
    }

    function computeDomainSeparator() internal view virtual returns (bytes32) {
        return keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256(bytes(StrHelper.bytes32ToString(_name))),
                keccak256("1"),
                block.chainid,
                address(this)
            )
        );
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 amount) internal virtual {
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

    function _burn(address from, uint256 amount) internal virtual {
        assembly {
            // balanceOf[from] -= amount;
            let _balance := sload(from)
            if lt(_balance, amount) {
                mstore(0x00, 0x13be252b) // TODO calcular keccak `InsufficientAllowance()`.
                revert(0x1c, 0x04)
            }
            sstore(from, sub(_balance, amount))
        }

        emit Transfer(from, address(0), amount);
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL HELPERS LOGIC
    //////////////////////////////////////////////////////////////*/

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        allowance[owner][spender] = amount;

        emit Approval(owner, spender, amount);
    }

    function _spendAllowance(address from, address to, uint256 amount) internal virtual {
        uint256 allowed = allowance[from][to]; // Saves gas for limited approvals.

        if (allowed != type(uint256).max) allowance[from][to] = allowed - amount;
    }

    function _transfer(address from, address to, uint256 amount) internal {
        assembly {
            // balanceOf[from] -= amount;
            let _balance := sload(from)
            if lt(_balance, amount) {
                mstore(0x00, 0x13be252b) // TODO calcular keccak `InsufficientAllowance()`.
                revert(0x1c, 0x04)
            }
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

/*
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

*/
