// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.10;

import "forge-std/Test.sol";

import {Nativo} from "src/Nativo.sol";
import {ERC3156BorrowerMock} from "./mock/BorrowerMock.sol";

// FLASHLOAN tests
contract ERC3156Test is Test {
    Nativo public nativo;
    address public immutable EOA = makeAddr("EOA");
    address public immutable manager = makeAddr("manager");
    address treasury = makeAddr("treasury");

    function setUp() public {
        vm.prank(manager);
        // name and symbol depend on the blockchain we are deploying
        nativo = new Nativo("Wrapped Nativo crypto", "nANY");

        vm.prank(manager);
        nativo.setTreasury(treasury);
    }

    function invariantMetadata() public {
        assertEq(nativo.name(), "Wrapped Nativo crypto", "Wrong name");
        assertEq(nativo.symbol(), "nANY", "Wrong symbol");
        assertEq(nativo.decimals(), 18, "Wrong decimals");
    }

    function testMaxFlashLoan() public {
        assertEq(nativo.maxFlashLoan(address(nativo)), 0);
        vm.expectRevert();
        nativo.maxFlashLoan(address(0));
        vm.expectRevert();
        nativo.maxFlashLoan(address(0xdead));
    }

    function testMaxFlashLoan2(uint112 _supply, uint112 _remove) public {
        uint256 supply = uint256(_supply);
        uint256 remove = uint256(_remove);
        vm.deal(EOA, supply);
        vm.prank(EOA);
        nativo.depositTo{value: supply}(EOA);
        assertEq(nativo.maxFlashLoan(address(nativo)), supply);

        remove = bound(remove, 0, supply);
        vm.prank(EOA);
        nativo.withdraw(remove);
        assertEq(nativo.maxFlashLoan(address(nativo)), supply - remove);
    }

    function testFlashFee() public {
        assertEq(nativo.flashFee(address(nativo), 0), 0);

        vm.expectRevert(abi.encodeWithSignature("ERC3156UnsupportedToken(address)", address(0)));
        nativo.flashFee(address(0), 0);
        vm.expectRevert(abi.encodeWithSignature("ERC3156UnsupportedToken(address)", address(0xdead)));
        nativo.flashFee(address(0xdead), 0);

        // 0.09% fee
        assertEq(nativo.flashFee(address(nativo), 10000), 9);
        assertEq(nativo.flashFee(address(nativo), 100000), 90);
    }

    function testFlashLoanSuccess() public {
        ERC3156BorrowerMock receiver = new ERC3156BorrowerMock(true, true);
        vm.expectRevert(abi.encodeWithSignature("ERC3156ExceededMaxLoan(uint256)", 0));
        nativo.flashLoan(receiver, address(nativo), 10000, "");

        address otherToken = makeAddr("otherToken");
        vm.expectRevert(abi.encodeWithSignature("ERC3156UnsupportedToken(address)", otherToken));
        nativo.flashLoan(receiver, otherToken, 10000, "");

        nativo.deposit{value: 10009}();
        vm.expectRevert("!implemented");
        nativo.flashLoan(receiver, address(nativo), 10000, "0x");

        vm.expectRevert(abi.encodeWithSignature("InsufficientBalance()"));
        nativo.flashLoan(receiver, address(nativo), 10000, "");

        vm.expectRevert(abi.encodeWithSignature("ERC3156ExceededMaxLoan(uint256)", 10009));
        nativo.flashLoan(receiver, address(nativo), 10010, "");

        // 1 token to pay the fee
        nativo.transfer(address(receiver), 9);
        nativo.flashLoan(receiver, address(nativo), 10000, "");

        assertEq(nativo.balanceOf(nativo.treasury()), 9);

        assertEq(nativo.totalSupply(), 10009);

        assertEq(nativo.balanceOf(address(receiver)), 0);
        assertEq(nativo.allowance(address(receiver), address(nativo)), 0);
    }

    function testMinFee() public {
        ERC3156BorrowerMock receiver = new ERC3156BorrowerMock(true, true);
        nativo.deposit{value: 10_000}();

        vm.expectRevert("ERC3156: min amount is 1000 wei");
        nativo.flashLoan(receiver, address(nativo), 9999, "");
    }

    function testCantReenter() public {
        ERC3156BorrowerMock receiver = new ERC3156BorrowerMock(true, true);
        nativo.deposit{value: 10_000}();

        vm.expectRevert("ERC3156: reentrancy not allowed");
        nativo.flashLoan(
            receiver,
            address(nativo),
            10000,
            abi.encodeWithSelector(nativo.flashLoan.selector, receiver, nativo, 10000, "")
        );
    }

    function testInvalidReturn() public {
        ERC3156BorrowerMock receiver = new ERC3156BorrowerMock(false, true);
        nativo.deposit{value: 10_000}();

        vm.expectRevert(abi.encodeWithSignature("ERC3156InvalidReceiver(address)", address(receiver)));
        nativo.flashLoan(receiver, address(nativo), 10000, "");
    }

    function testMissingApprove() public {
        ERC3156BorrowerMock receiver = new ERC3156BorrowerMock(true, false);
        nativo.deposit{value: 10_000}();

        vm.expectRevert();
        nativo.flashLoan(receiver, address(nativo), 1000, "");
    }

    function testInsufficientFunds() public {
        ERC3156BorrowerMock receiver = new ERC3156BorrowerMock(true, true);
        nativo.deposit{value: 10_010}();

        bytes memory transferOneNative = abi.encodeWithSignature("transfer(address,uint256)", address(this), 1);

        nativo.transfer(address(receiver), 9);
        vm.expectRevert();
        nativo.flashLoan(receiver, address(nativo), 10000, transferOneNative);

        nativo.transfer(address(receiver), 1);
        nativo.flashLoan(receiver, address(nativo), 10000, transferOneNative);
    }
}
