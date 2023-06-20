// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.10;

import "forge-std/Test.sol";

import {Nativo} from "src/Nativo.sol";
import {ERC3156BorrowerMock} from "./mock/BorrowerMock.sol";

// FLASHLOAN tests
contract ERC3156Test is Test {
    Nativo public nativo;
    address public immutable EOA = makeAddr("EOA");

    function setUp() public {
        // name and symbol depend on the blockchain we are deploying
        nativo = new Nativo("Wrapped Nativo crypto", "nANY");
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

        vm.expectRevert();
        nativo.flashFee(address(0), 0);
        vm.expectRevert();
        nativo.flashFee(address(0xdead), 0);

        // 0.1% fee
        assertEq(nativo.flashFee(address(nativo), 1000), 1);
        assertEq(nativo.flashFee(address(nativo), 10000), 10);
    }

    function testFlashLoanSuccess() public {
        ERC3156BorrowerMock receiver = new ERC3156BorrowerMock(true, true);
        vm.expectRevert(abi.encodeWithSignature("ERC3156ExceededMaxLoan(uint256)", 0));
        nativo.flashLoan(receiver, address(nativo), 1000, "");

        nativo.deposit{value: 1001}();
        vm.expectRevert("!implemented");
        nativo.flashLoan(receiver, address(nativo), 1000, "0x");

        vm.expectRevert(abi.encodeWithSignature("InsufficientAllowance()"));
        nativo.flashLoan(receiver, address(nativo), 1000, "");

        vm.expectRevert(abi.encodeWithSignature("ERC3156ExceededMaxLoan(uint256)", 1001));
        nativo.flashLoan(receiver, address(nativo), 1002, "");

        // 1 token to pay the fee
        nativo.transfer(address(receiver), 1);
        nativo.flashLoan(receiver, address(nativo), 1000, "");

        assertEq(nativo.balanceOf(nativo.treasury()), 1);

        assertEq(nativo.totalSupply(), 1001);

        assertEq(nativo.balanceOf(address(receiver)), 0);
        assertEq(nativo.allowance(address(receiver), address(nativo)), 0);
    }
}
