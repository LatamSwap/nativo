// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/ERC/ERC20.sol";

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
        _spendAllowance(from, msg.sender, amount);
        _burn(from, amount);
    }

    function tr(address to, uint256 amount) public {
        _transfer(msg.sender, to, amount);
    }
}

contract Erc20Test is Test {
    Mock public token;

    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Approval(address indexed owner, address indexed spender, uint256 amount);

    function setUp() public {
        token = new Mock();
    }

    function testMetadata() public {
        Mock _token = new Mock();
        assertEq(_token.name(), "Mock");
        assertEq(_token.symbol(), "MOCK");
        bytes32 expectedDomainSeparator = keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256(bytes(_token.name())),
                keccak256("1"),
                block.chainid,
                address(_token)
            )
        );

        assertEq(_token.DOMAIN_SEPARATOR(), expectedDomainSeparator);

        vm.chainId(31337);
        expectedDomainSeparator = keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256("Mock"),
                keccak256("1"),
                block.chainid,
                address(_token)
            )
        );
        assertEq(_token.DOMAIN_SEPARATOR(), expectedDomainSeparator);
    }

    function testMint(uint256 toMint, uint256 toBurn) public {
        toBurn = bound(toBurn, 0, toMint);

        vm.expectEmit(true, true, true, true);
        emit Transfer(address(0), address(this), toMint);
        token.mint(address(this), toMint);
        assertEq(token.balanceOf(address(this)), toMint);

        vm.expectEmit(true, true, true, true);
        emit Transfer(address(this), address(0), toBurn);
        token.burn(toBurn);
        assertEq(token.balanceOf(address(this)), toMint - toBurn);
    }

    function testTransfer(address to, uint256 amount) public {
        token.mint(address(this), amount);

        vm.expectEmit(true, true, true, true);
        emit Transfer(address(this), to, amount);
        token.transfer(to, amount);
        if (to != address(this)) assertEq(token.balanceOf(address(this)), 0);
        assertEq(token.balanceOf(to), amount);
    }

    function testTransferError() public {
        vm.expectRevert(ERC20.InsufficientBalance.selector);
        token.transfer(address(0xBEEF), 1 ether);
    }

    function testTransfer2(address from, address to, uint256 amount) public {
        token.mint(from, amount);

        vm.expectEmit(true, true, true, true);
        emit Approval(from, address(this), amount);
        vm.prank(from);
        token.approve(address(this), amount);

        vm.expectEmit(true, true, true, true);
        emit Transfer(from, to, amount);
        token.transferFrom(from, to, amount);
        if (to != from) assertEq(token.balanceOf(from), 0);
        assertEq(token.balanceOf(to), amount);
    }

    function testInternalTransfer(address to, uint256 amount) public {
        token.mint(address(this), amount);

        vm.expectEmit(true, true, true, true);
        emit Transfer(address(this), to, amount);
        token.tr(to, amount);
        if (to != address(this)) assertEq(token.balanceOf(address(this)), 0);
        assertEq(token.balanceOf(to), amount);
    }

    function testBurnFrom() external {
        address eoa = makeAddr("EOA");

        vm.expectEmit(true, true, true, true);
        emit Transfer(address(0), eoa, 100);
        token.mint(eoa, 100);

        vm.expectEmit(true, true, true, true);
        emit Approval(eoa, address(this), 50);
        vm.prank(eoa);
        token.approve(address(this), 50);

        vm.expectEmit(true, true, true, true);
        emit Transfer(eoa, address(0), 20);
        token.burnFrom(eoa, 20);
        assertEq(token.balanceOf(eoa), 80);
        assertEq(token.allowance(eoa, address(this)), 30);
    }

    bytes32 constant PERMIT_TYPEHASH =
        keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");

    function invariantMetadata() public {
        assertEq(token.name(), "Mock");
        assertEq(token.symbol(), "MOCK");
        assertEq(token.decimals(), 18);

        // total supply us total native balance of the contract
        assertEq(token.totalSupply(), 0);
    }

    function testMint() public {
        token.mint(address(0xBEEF), 1e18);

        assertEq(token.balanceOf(address(0xBEEF)), 1e18);
    }

    function testBurn() public {
        token.mint(address(0xBEEF), 1e18);
        token.burn(address(0xBEEF), 0.9e18);

        assertEq(token.balanceOf(address(0xBEEF)), 0.1e18);
    }

    function testBurnError() public {
        vm.expectRevert(ERC20.InsufficientBalance.selector);
        token.burn(address(0xBEEF), 1 ether);
    }

    function testApprove() public {
        assertTrue(token.approve(address(0xBEEF), 1e18));

        assertEq(token.allowance(address(this), address(0xBEEF)), 1e18);
    }

    function testTransfer3() public {
        token.mint(address(this), 1e18);

        assertTrue(token.transfer(address(0xBEEF), 1e18));

        assertEq(token.balanceOf(address(this)), 0);
        assertEq(token.balanceOf(address(0xBEEF)), 1e18);
    }

    function testTransferFrom() public {
        address from = address(0xABCD);

        token.mint(from, 1e18);

        vm.prank(from);
        token.approve(address(this), 1e18);

        assertTrue(token.transferFrom(from, address(0xBEEF), 1e18));

        assertEq(token.allowance(from, address(this)), 0);

        assertEq(token.balanceOf(from), 0);
        assertEq(token.balanceOf(address(0xBEEF)), 1e18);
    }

    function testInfiniteApproveTransferFrom() public {
        address from = address(0xABCD);

        token.mint(from, 1e18);
        assertEq(token.balanceOf(from), 1e18);

        vm.prank(from);
        token.approve(address(this), type(uint256).max);

        assertTrue(token.transferFrom(from, address(0xBEEF), 1e18));

        assertEq(token.allowance(from, address(this)), type(uint256).max);

        assertEq(token.balanceOf(from), 0, "balance of from");
        assertEq(token.balanceOf(address(0xBEEF)), 1e18, "balance of beef");
    }

    function testPermit() public {
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

        assertEq(token.allowance(owner, address(0xCAFE)), 1e18);
        assertEq(token.nonces(owner), 1);
    }

    function testFailTransferInsufficientBalance() public {
        token.mint(address(this), 0.9e18);
        token.transfer(address(0xBEEF), 1e18);
    }

    function testFailTransferFromInsufficientAllowance() public {
        address from = address(0xABCD);

        token.mint(from, 1e18);

        vm.prank(from);
        token.approve(address(this), 0.9e18);

        token.transferFrom(from, address(0xBEEF), 1e18);
    }

    function testFailTransferFromInsufficientBalance() public {
        address from = address(0xABCD);

        token.mint(from, 0.9e18);

        vm.prank(from);
        token.approve(address(this), 1e18);

        token.transferFrom(from, address(0xBEEF), 1e18);
    }

    function testFailPermitBadNonce() public {
        (address owner, uint256 privateKey) = makeAddrAndKey("owner");

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            privateKey,
            keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    token.DOMAIN_SEPARATOR(),
                    keccak256(abi.encode(PERMIT_TYPEHASH, owner, address(0xCAFE), 1e18, 1, block.timestamp))
                )
            )
        );

        token.permit(owner, address(0xCAFE), 1e18, block.timestamp, v, r, s);
    }

    function testFailPermitBadDeadline() public {
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

        token.permit(owner, address(0xCAFE), 1e18, block.timestamp + 1, v, r, s);
    }

    function testFailPermitPastDeadline() public {
        uint256 oldTimestamp = block.timestamp;
        (address owner, uint256 privateKey) = makeAddrAndKey("owner");

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            privateKey,
            keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    token.DOMAIN_SEPARATOR(),
                    keccak256(abi.encode(PERMIT_TYPEHASH, owner, address(0xCAFE), 1e18, 0, oldTimestamp))
                )
            )
        );

        vm.warp(block.timestamp + 1);
        token.permit(owner, address(0xCAFE), 1e18, oldTimestamp, v, r, s);
    }

    function testFailPermitReplay() public {
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
        token.permit(owner, address(0xCAFE), 1e18, block.timestamp, v, r, s);
    }

    function testMint(address from, uint256 amount) public {
        token.mint(from, amount);

        assertEq(token.balanceOf(from), amount);
    }

    function testBurn(address from, uint256 mintAmount, uint256 burnAmount) public {
        burnAmount = bound(burnAmount, 0, mintAmount);

        token.mint(from, mintAmount);
        token.burn(from, burnAmount);

        assertEq(token.balanceOf(from), mintAmount - burnAmount);
    }

    function testApprove(address to, uint256 amount) public {
        assertTrue(token.approve(to, amount));

        assertEq(token.allowance(address(this), to), amount);
    }

    function testTransfer4(address from, uint256 amount) public {
        token.mint(address(this), amount);

        assertTrue(token.transfer(from, amount));

        if (address(this) == from) {
            assertEq(token.balanceOf(address(this)), amount);
        } else {
            assertEq(token.balanceOf(address(this)), 0);
            assertEq(token.balanceOf(from), amount);
        }
    }

    function testTransferFrom(address to, uint256 approval, uint256 amount) public {
        amount = bound(amount, 0, approval);

        address from = address(0xABCD);

        token.mint(from, amount);

        vm.prank(from);
        token.approve(address(this), approval);

        assertTrue(token.transferFrom(from, to, amount));

        uint256 app = from == address(this) || approval == type(uint256).max ? approval : approval - amount;
        assertEq(token.allowance(from, address(this)), app);

        if (from == to) {
            assertEq(token.balanceOf(from), amount);
        } else {
            assertEq(token.balanceOf(from), 0);
            assertEq(token.balanceOf(to), amount);
        }
    }

    function testPermit(uint248 privKey, address to, uint256 amount, uint256 deadline) public {
        uint256 privateKey = privKey;
        if (deadline < block.timestamp) deadline = block.timestamp;
        if (privateKey == 0) privateKey = 1;

        address owner = vm.addr(privateKey);

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            privateKey,
            keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    token.DOMAIN_SEPARATOR(),
                    keccak256(abi.encode(PERMIT_TYPEHASH, owner, to, amount, 0, deadline))
                )
            )
        );

        token.permit(owner, to, amount, deadline, v, r, s);

        assertEq(token.allowance(owner, to), amount);
        assertEq(token.nonces(owner), 1);
    }

    function testFailBurnInsufficientBalance(address to, uint256 mintAmount, uint256 burnAmount) public {
        burnAmount = bound(burnAmount, mintAmount + 1, type(uint256).max);

        token.mint(to, mintAmount);
        token.burn(to, burnAmount);
    }

    function testFailTransferInsufficientBalance(address to, uint256 mintAmount, uint256 sendAmount) public {
        sendAmount = bound(sendAmount, mintAmount + 1, type(uint256).max);

        token.mint(address(this), mintAmount);
        token.transfer(to, sendAmount);
    }

    function testFailTransferFromInsufficientAllowance(address to, uint256 approval, uint256 amount) public {
        amount = bound(amount, approval + 1, type(uint256).max);

        address from = address(0xABCD);

        token.mint(from, amount);

        vm.prank(from);
        token.approve(address(this), approval);

        token.transferFrom(from, to, amount);
    }

    function testFailTransferFromInsufficientBalance(address to, uint256 mintAmount, uint256 sendAmount) public {
        sendAmount = bound(sendAmount, mintAmount + 1, type(uint256).max);

        address from = address(0xABCD);

        token.mint(from, mintAmount);

        vm.prank(from);
        token.approve(address(this), sendAmount);

        token.transferFrom(from, to, sendAmount);
    }

    function testFailPermitBadNonce(uint256 privateKey, address to, uint256 amount, uint256 deadline, uint256 nonce)
        public
    {
        if (deadline < block.timestamp) deadline = block.timestamp;
        if (privateKey == 0) privateKey = 1;
        if (nonce == 0) nonce = 1;

        address owner = vm.addr(privateKey);

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            privateKey,
            keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    token.DOMAIN_SEPARATOR(),
                    keccak256(abi.encode(PERMIT_TYPEHASH, owner, to, amount, nonce, deadline))
                )
            )
        );

        token.permit(owner, to, amount, deadline, v, r, s);
    }

    function testFailPermitBadDeadline(uint256 privateKey, address to, uint256 amount, uint256 deadline) public {
        if (deadline < block.timestamp) deadline = block.timestamp;
        if (privateKey == 0) privateKey = 1;

        address owner = vm.addr(privateKey);

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            privateKey,
            keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    token.DOMAIN_SEPARATOR(),
                    keccak256(abi.encode(PERMIT_TYPEHASH, owner, to, amount, 0, deadline))
                )
            )
        );

        token.permit(owner, to, amount, deadline + 1, v, r, s);
    }

    function testFailPermitPastDeadline(uint256 privateKey, address to, uint256 amount, uint256 deadline) public {
        deadline = bound(deadline, 0, block.timestamp - 1);
        if (privateKey == 0) privateKey = 1;

        address owner = vm.addr(privateKey);

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            privateKey,
            keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    token.DOMAIN_SEPARATOR(),
                    keccak256(abi.encode(PERMIT_TYPEHASH, owner, to, amount, 0, deadline))
                )
            )
        );

        token.permit(owner, to, amount, deadline, v, r, s);
    }

    function testFailPermitReplay(uint256 privateKey, address to, uint256 amount, uint256 deadline) public {
        if (deadline < block.timestamp) deadline = block.timestamp;
        if (privateKey == 0) privateKey = 1;

        address owner = vm.addr(privateKey);

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            privateKey,
            keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    token.DOMAIN_SEPARATOR(),
                    keccak256(abi.encode(PERMIT_TYPEHASH, owner, to, amount, 0, deadline))
                )
            )
        );

        token.permit(owner, to, amount, deadline, v, r, s);
        token.permit(owner, to, amount, deadline, v, r, s);
    }
}
