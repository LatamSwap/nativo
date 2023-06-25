// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.10;

import "forge-std/Test.sol";

import {Nativo} from "src/Nativo.sol";
import {DeployWeth} from "test/mock/WethDeploy.sol";
import {Benchmark} from "test/Benchmark.sol";
import {WETH} from "solmate/tokens/WETH.sol";
import {SafeTransferLib} from "solmate/utils/SafeTransferLib.sol";

contract NativoUXGasTest is Test, Benchmark {
    Nativo public nativo;
    WETH public weth;
    address EOAweth = makeAddr("EOAweth");
    address EOAnativo = makeAddr("EOAnativo");

    UxWithNativo public uxWithNativo;
    UxWithWETH public uxWithWETH;

    function setUp() public virtual {
        vm.roll(1);
        vm.warp(1);

        // name and symbol depend on the blockchain we are deploying

        nativo = new Nativo("Nativo Wrapped Ether", "nETH");
        weth = WETH(payable(DeployWeth.deploy()));

        uxWithNativo = new UxWithNativo(nativo);
        uxWithWETH = new UxWithWETH(weth);

        vm.deal(EOAweth, 1.1 ether);
        vm.deal(EOAnativo, 1.1 ether);
    }

    function testBenchmarkDepositTo() public {
        // lets try to depositTo using weth
        vm.startPrank(EOAweth);
        benchmarkStart("weth.depositTo()");
        uxWithWETH.depositTo{value: 1 ether}(address(0x01));
        benchmarkEnd();
        vm.stopPrank();

        // lets try to depositTo using nativo
        vm.startPrank(EOAnativo);
        benchmarkStart("nativo.depositTo()");
        uxWithNativo.depositTo{value: 1 ether}(address(0x02));
        benchmarkEnd();
        vm.stopPrank();

        assertEq(weth.balanceOf(address(0x01)), 1 ether);
        assertEq(nativo.balanceOf(address(0x02)), 1 ether);
    }

    function testBenchmarkWithdrawAll() public {
        // lets try to withdrawAll using weth
        vm.startPrank(EOAweth);
        weth.deposit{value: 1 ether}();
        benchmarkStart("weth.withdrawAll()");
        weth.withdraw(weth.balanceOf(EOAweth));
        benchmarkEnd();
        vm.stopPrank();

        // lets try to withdrawAll using nativo
        vm.startPrank(EOAnativo);
        nativo.deposit{value: 1 ether}();
        benchmarkStart("nativo.withdrawAll()");
        nativo.withdrawAll();
        benchmarkEnd();
        vm.stopPrank();

        assertEq(EOAnativo.balance, 1.1 ether);
        assertEq(nativo.balanceOf(EOAnativo), 0 ether);
    }

    function testBenchmarkWithdrawTo() public {
        weth.deposit{value: 1 ether}();
        weth.transfer(address(uxWithWETH), 1 ether);

        nativo.deposit{value: 1 ether}();
        nativo.transfer(address(uxWithNativo), 1 ether);

        // lets try to withdrawTo using weth
        vm.startPrank(EOAweth);
        benchmarkStart("weth.withdrawTo()");
        uxWithWETH.withdrawTo(address(0x01), 0.1 ether);
        benchmarkEnd();
        vm.stopPrank();

        // lets try to withdrawTo using nativo
        vm.startPrank(EOAnativo);
        benchmarkStart("nativo.withdrawTo()");
        uxWithNativo.withdrawTo(address(0x02), 0.1 ether);
        benchmarkEnd();
        vm.stopPrank();

        assertEq(address(0x01).balance, 0.1 ether);
        assertEq(address(0x02).balance, 0.1 ether);
    }

    function testBenchmarkWithdrawAllTo() public {
        weth.deposit{value: 1 ether}();
        weth.transfer(address(uxWithWETH), 1 ether);

        nativo.deposit{value: 1 ether}();
        nativo.transfer(address(uxWithNativo), 1 ether);

        // lets try to withdrawAllTo using weth
        vm.startPrank(EOAweth);
        benchmarkStart("weth.withdrawAllTo()");
        uxWithWETH.withdrawAllTo(address(0x01));
        benchmarkEnd();
        vm.stopPrank();

        // lets try to withdrawAllTo using nativo
        vm.startPrank(EOAnativo);
        benchmarkStart("nativo.withdrawAllTo()");
        uxWithNativo.withdrawAllTo(address(0x02));
        benchmarkEnd();
        vm.stopPrank();

        assertEq(address(0x01).balance, 1 ether);
        assertEq(address(0x02).balance, 1 ether);
    }

    function testBenchmarkWithdrawFromTo() public {
        vm.startPrank(EOAweth);
        weth.deposit{value: 1 ether}();
        weth.approve(address(uxWithWETH), type(uint256).max);
        vm.stopPrank();

        vm.startPrank(EOAnativo);
        nativo.deposit{value: 1 ether}();
        nativo.approve(address(uxWithNativo), type(uint256).max);
        vm.stopPrank();

        // lets try to withdrawFromTo using weth
        benchmarkStart("weth.withdrawFromTo()");
        uxWithWETH.withdrawFromTo(address(EOAweth), address(0x01), 0.5 ether);
        benchmarkEnd();

        // lets try to withdrawFromTo using nativo
        benchmarkStart("nativo.withdrawFromTo()");
        uxWithNativo.withdrawFromTo(address(EOAnativo), address(0x02), 0.5 ether);
        benchmarkEnd();

        assertEq(address(0x01).balance, 0.5 ether);
        assertEq(address(0x02).balance, 0.5 ether);
    }

    function testBenchmarkWithdrawAllFromTo() public {
        vm.startPrank(EOAweth);
        weth.deposit{value: 1 ether}();
        weth.approve(address(uxWithWETH), type(uint256).max);
        vm.stopPrank();

        vm.startPrank(EOAnativo);
        nativo.deposit{value: 1 ether}();
        nativo.approve(address(uxWithNativo), type(uint256).max);
        vm.stopPrank();

        // lets try to withdrawAllFromTo using weth
        benchmarkStart("weth.withdrawAllFromTo()");
        uxWithWETH.withdrawAllFromTo(address(EOAweth), address(0x01));
        benchmarkEnd();

        // lets try to withdrawAllFromTo using nativo
        benchmarkStart("nativo.withdrawAllFromTo()");
        uxWithNativo.withdrawAllFromTo(address(EOAnativo), address(0x02));
        benchmarkEnd();

        assertEq(address(0x01).balance, 1 ether);
        assertEq(address(0x02).balance, 1 ether);
    }
}

contract UxWithWETH {
    WETH public immutable weth;

    constructor(WETH _weth) {
        weth = _weth;
    }

    function depositTo(address dst) public payable {
        weth.deposit{value: msg.value}();
        weth.transfer(dst, msg.value);
    }

    function withdrawTo(address dst, uint256 amount) public {
        weth.withdraw(amount);
        SafeTransferLib.safeTransferETH(dst, amount);
    }

    function withdrawAllTo(address dst) public {
        uint256 amount = weth.balanceOf(address(this));
        weth.withdraw(amount);
        SafeTransferLib.safeTransferETH(dst, amount);
    }

    function withdrawFromTo(address from, address to, uint256 amount) public {
        weth.transferFrom(from, address(this), amount);
        weth.withdraw(amount);
        SafeTransferLib.safeTransferETH(to, amount);
    }

    function withdrawAllFromTo(address from, address to) public {
        uint256 amount = weth.balanceOf(from);
        weth.transferFrom(from, address(this), amount);
        weth.withdraw(amount);
        SafeTransferLib.safeTransferETH(to, amount);
    }

    receive() external payable {
        require(msg.sender == address(weth));
    }
}

contract UxWithNativo {
    Nativo public immutable nativo;

    constructor(Nativo _nativo) {
        nativo = _nativo;
    }

    function depositTo(address dst) public payable {
        nativo.depositTo{value: msg.value}(dst);
    }

    function withdrawTo(address dst, uint256 amount) public {
        nativo.withdrawTo(dst, amount);
    }

    function withdrawAllTo(address dst) public {
        nativo.withdrawAllTo(dst);
    }

    function withdrawFromTo(address from, address to, uint256 amount) public {
        nativo.withdrawFromTo(from, to, amount);
    }

    function withdrawAllFromTo(address from, address to) public {
        nativo.withdrawAllFromTo(from, to);
    }
}
