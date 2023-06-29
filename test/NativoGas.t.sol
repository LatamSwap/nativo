// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.10;

import "forge-std/Test.sol";

import {Nativo} from "src/Nativo.sol";
import {DeployWeth} from "test/mock/WethDeploy.sol";
import {Benchmark} from "test/Benchmark.sol";
import {GasSnapshot} from "forge-gas-snapshot/GasSnapshot.sol";


contract NativoGasTest is Test, GasSnapshot {
    Nativo public nativo;
    Nativo public weth;
    address EOAweth = makeAddr("EOAweth");
    address EOAnativo = makeAddr("EOAnativo");

    function setUp() public virtual {
        vm.roll(1);
        vm.warp(1);

        // name and symbol depend on the blockchain we are deploying

        // address treasury = 0x00000000fFFffDB6Fc1F34ac4aD25dd9eF7031eF;
        address _deployedNativo = address(new Nativo("Nativo Wrapped Ether", "WETH"));
        bytes memory code = _deployedNativo.code;
        address payable targetAddr = payable(address(0x000000006789fDb6Fc1F34aC4ad25dD9EF7031Ef));
        vm.etch(targetAddr, code);
        nativo = Nativo(targetAddr);

        // main net WETH address
        vm.etch(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2, address(DeployWeth.deploy()).code);
        weth = Nativo(payable(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2));

        bytes32 _slot;

        /*
        @dev not necesary, but just in case
        // lest copy slots to proper init the contracts that were etch;
        // 10 first slots should be enough (depend on how many storage variables are in the contract)
        for (uint256 i; i < 10; i++) {
            _slot = bytes32(i);
            vm.store(address(nativo), _slot, vm.load(_deployedNativo, _slot));
        }
        */
        _slot = bytes32(uint256(keccak256("ERC3156_FLASHMINTED")) - 1);
        vm.store(address(nativo), _slot, vm.load(_deployedNativo, _slot));

        vm.store(address(weth), bytes32(0), bytes32(0x577261707065642045746865720000000000000000000000000000000000001a));
        vm.store(
            address(weth),
            bytes32(uint256(1)),
            bytes32(0x5745544800000000000000000000000000000000000000000000000000000008)
        );
        vm.store(
            address(weth),
            bytes32(uint256(2)),
            bytes32(0x0000000000000000000000000000000000000000000000000000000000000012)
        );

        assertEq(nativo.name(), "Nativo Wrapped Ether");
        assertEq(nativo.symbol(), "WETH");
        assertEq(weth.name(), "Wrapped Ether");
        assertEq(weth.symbol(), "WETH");
    }

    function testMetadata() public {
        assertEq(nativo.decimals(), 18);
        assertEq(weth.decimals(), 18);

        assertEq(nativo.totalSupply(), 0);
        assertEq(weth.totalSupply(), 0);
    }

    function testBenchmarkMetadata() public {
        snapStart("nativo.decimals()");
        nativo.decimals();
        snapEnd();

        snapStart("weth.decimals()");
        weth.decimals();
        snapEnd();

        snapStart("nativo.totalSupply()");
        nativo.totalSupply();
        snapEnd();

        snapStart("weth.totalSupply()");
        weth.totalSupply();
        snapEnd();
    }

    function testDeposit() public {
        vm.deal(EOAweth, 10 ether);
        vm.deal(EOAnativo, 10 ether);

        vm.startPrank(EOAnativo);
        snapStart("nativo.deposit()");
        nativo.deposit{value: 5 ether}();
        snapEnd();
        vm.stopPrank();

        vm.startPrank(EOAweth);
        snapStart("weth.deposit()");
        weth.deposit{value: 5 ether}();
        snapEnd();
        vm.stopPrank();

        uint256 balance = 1;
        snapStart("nativo.balanceOf()");
        balance = nativo.balanceOf(address(this));
        snapEnd();
        assertEq(nativo.balanceOf(address(this)), balance);

        balance = 1;

        snapStart("weth.balanceOf()");
        balance = weth.balanceOf(address(this));
        snapEnd();
        assertEq(weth.balanceOf(address(this)), balance);

        vm.startPrank(EOAweth);
        snapStart("weth.withdraw()");
        weth.withdraw(4 ether);
        snapEnd();
        vm.stopPrank();

        vm.startPrank(EOAnativo);
        snapStart("nativo.withdraw()");
        nativo.withdraw(4 ether);
        snapEnd();
        vm.stopPrank();

        vm.startPrank(EOAweth);
        snapStart("weth.transfer()");
        weth.transfer(address(0x01), 0.1 ether);
        snapEnd();
        vm.stopPrank();

        vm.startPrank(EOAnativo);
        snapStart("nativo.transfer()");
        nativo.transfer(address(0x02), 0.1 ether);
        snapEnd();
        vm.stopPrank();
    }

    function testBenchmarkApprove() public {
        vm.deal(EOAnativo, 1 ether);
        vm.deal(EOAweth, 1 ether);

        vm.prank(EOAnativo);
        nativo.deposit{value: 1 ether}();

        vm.prank(EOAweth);
        weth.deposit{value: 1 ether}();

        vm.startPrank(EOAweth);
        snapStart("weth.approve()");
        weth.approve(address(0x01), 0.1 ether);
        snapEnd();
        vm.stopPrank();

        vm.startPrank(EOAnativo);
        snapStart("nativo.approve()");
        nativo.approve(address(0x01), 0.1 ether);
        snapEnd();
        vm.stopPrank();

        vm.startPrank(address(0x01));
        snapStart("nativo.transferFrom()");
        nativo.transferFrom(EOAnativo, address(0x02), 0.01 ether);
        snapEnd();
        vm.stopPrank();

        vm.startPrank(address(0x01));
        snapStart("weth.transferFrom()");
        weth.transferFrom(EOAweth, address(0x02), 0.01 ether);
        snapEnd();
        vm.stopPrank();
    }

    function testBenchmarkInfinityApprove() public {
        vm.deal(EOAnativo, 1 ether);
        vm.deal(EOAweth, 1 ether);

        vm.prank(EOAnativo);
        nativo.deposit{value: 1 ether}();

        vm.prank(EOAweth);
        weth.deposit{value: 1 ether}();

        vm.startPrank(EOAweth);
        snapStart("weth.approve() infinity");
        weth.approve(address(0x01), type(uint256).max);
        snapEnd();
        vm.stopPrank();

        vm.startPrank(EOAnativo);
        snapStart("nativo.approve() infinity");
        nativo.approve(address(0x01), type(uint256).max);
        snapEnd();
        vm.stopPrank();

        vm.startPrank(address(0x01));
        snapStart("nativo.transferFrom() infinity");
        nativo.transferFrom(EOAnativo, address(0x02), 0.01 ether);
        snapEnd();
        vm.stopPrank();

        vm.startPrank(address(0x01));
        snapStart("weth.transferFrom() infinity");
        weth.transferFrom(EOAweth, address(0x02), 0.01 ether);
        snapEnd();
        vm.stopPrank();
    }

    function testNewUx() public {

    }
}
