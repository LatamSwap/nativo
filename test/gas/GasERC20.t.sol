// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "src/ERC/ERC20.sol";

contract Mock is ERC20("Mock", "MOCK") {
    function totalSupply() external view override returns (uint256) {
        return 0;
    }

    function mint(address to, uint256 amount) public {
        _mint(to, amount);
    }

    function burn(uint256 amount) public {
        _burn(msg.sender, amount);
    }

    // @dev burn with no allowance check
    function burn(address from, uint256 amount) public {
        _burn(from, amount);
    }

    function burnFrom(address from, uint256 amount) public {
        _useAllowance(from, amount);
        _burn(from, amount);
    }

    function tr(address to, uint256 amount) public {
        _transfer(msg.sender, to, amount);
    }
}

contract GasErc20Test is Test {
    Mock public token;

    function setUp() public {
        token = new Mock();
    }

    function test_Gas_BurnFrom() external {
        address eoa = makeAddr("EOA");

        
        token.mint(eoa, 100);
        vm.prank(eoa);
        token.approve(address(this), 50);      
        token.burnFrom(eoa, 20);
    }

    bytes32 constant PERMIT_TYPEHASH =
        keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");

   
    function test_Gas_Mint() public {
        token.mint(address(0xBEEF), 1e18);

        assertEq(token.balanceOf(address(0xBEEF)), 1e18);
    }

    function test_Gas_Burn() public {
        token.mint(address(0xBEEF), 1e18);
        token.burn(address(0xBEEF), 0.9e18);
    }

    function test_Gas_Approve() public {
        token.approve(address(0xBEEF), 1e18);
    }

    function test_Gas_Transfer3() public {
        token.mint(address(this), 1e18);
        token.transfer(address(0xBEEF), 1e18);
    }

    function test_Gas_TransferFrom() public {
        address from = address(0xABCD);

        token.mint(from, 1e18);

        vm.prank(from);
        token.approve(address(this), 1e18);
        token.transferFrom(from, address(0xBEEF), 1e18);
    }

    function test_Gas_InfiniteApproveTransferFrom() public {
        address from = address(0xABCD);

        token.mint(from, 1e18);

        vm.prank(from);
        token.approve(address(this), type(uint256).max);
        token.transferFrom(from, address(0xBEEF), 1e18);

    }

    function test_Gas_Permit() public {
        (address owner, uint256 privateKey) = makeAddrAndKey("owner");

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            privateKey,
            keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    token.DOMAIN_SEPARATOR(),
                    keccak256(abi.encode(PERMIT_TYPEHASH, owner, address(0xCAFE), 1e18, 0, block.timestamp))
                )
            )
        );

        token.permit(owner, address(0xCAFE), 1e18, block.timestamp, v, r, s);
    }
}
