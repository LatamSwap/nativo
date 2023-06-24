// SPDX-License-Identifier: GPL-3.0-or-later
// Based on https://github.com/horsefacts/weth-invariant-testing
// @author horsefacts
pragma solidity ^0.8.13;

import {CommonBase} from "forge-std/Base.sol";
import {StdCheats} from "forge-std/StdCheats.sol";
import {StdUtils} from "forge-std/StdUtils.sol";
import {console} from "forge-std/console.sol";
import {AddressSet, LibAddressSet} from "../helpers/AddressSet.sol";
import {Nativo} from "../../src/Nativo.sol";

uint256 constant ETH_SUPPLY = 120_500_000 ether;

contract ForcePush {
    constructor(address dst) payable {
        selfdestruct(payable(dst));
    }
}

contract Handler is CommonBase, StdCheats, StdUtils {
    using LibAddressSet for AddressSet;

    Nativo public nativo;

    uint256 public ghost_depositSum;
    uint256 public ghost_withdrawSum;
    uint256 public ghost_forcePushSum;

    uint256 public ghost_zeroWithdrawals;
    uint256 public ghost_zeroTransfers;
    uint256 public ghost_zeroTransferFroms;

    mapping(bytes32 => uint256) public calls;

    AddressSet internal _actors;
    address internal currentActor;

    modifier createActor() {
        currentActor = msg.sender;
        _actors.add(msg.sender);
        _;
    }

    modifier useActor(uint256 actorIndexSeed) {
        currentActor = _actors.rand(actorIndexSeed);
        _;
    }

    modifier countCall(bytes32 key) {
        calls[key]++;
        _;
    }

    constructor(Nativo _nativo) {
        nativo = _nativo;
        deal(address(this), ETH_SUPPLY);
    }

    function deposit(uint256 amount) public createActor countCall("deposit") {
        require(currentActor != address(nativo), "nativo cant deposit");
        amount = bound(amount, 0, address(this).balance);
        _pay(currentActor, amount);

        vm.prank(currentActor);
        nativo.deposit{value: amount}();

        ghost_depositSum += amount;
    }

    function withdraw(uint256 actorSeed, uint256 amount) public useActor(actorSeed) countCall("withdraw") {
        require(currentActor != address(nativo), "nativo cant deposit");
        amount = bound(amount, 0, nativo.balanceOf(currentActor));
        if (amount == 0) ghost_zeroWithdrawals++;

        vm.startPrank(currentActor);
        nativo.withdraw(amount);
        _pay(address(this), amount);
        vm.stopPrank();

        ghost_withdrawSum += amount;
    }

    function withdrawAll(uint256 actorSeed) public useActor(actorSeed) countCall("withdrawAll") {
        require(currentActor != address(nativo), "nativo cant deposit");
        uint256 amount = nativo.balanceOf(currentActor);
        if (amount == 0) ghost_zeroWithdrawals++;

        vm.startPrank(currentActor);
        nativo.withdrawAll();
        _pay(address(this), amount);
        vm.stopPrank();

        ghost_withdrawSum += amount;
    }

    function withdrawAllTo(uint256 actorSeed, uint256 actorTo) public useActor(actorSeed) countCall("withdrawAllTo") {
        require(currentActor != address(nativo), "nativo cant deposit");
        uint256 amount = nativo.balanceOf(currentActor);
        if (amount == 0) ghost_zeroWithdrawals++;

        vm.prank(currentActor);
        nativo.withdrawAllTo(_actors.rand(actorTo));

        vm.prank(_actors.rand(actorTo));
        _pay(address(this), amount);

        ghost_withdrawSum += amount;
    }

    function approve(uint256 actorSeed, uint256 spenderSeed, uint256 amount)
        public
        useActor(actorSeed)
        countCall("approve")
    {
        require(currentActor != address(nativo), "nativo cant deposit");
        address spender = _actors.rand(spenderSeed);

        vm.prank(currentActor);
        nativo.approve(spender, amount);
    }

    function transfer(uint256 actorSeed, uint256 toSeed, uint256 amount)
        public
        useActor(actorSeed)
        countCall("transfer")
    {
        require(currentActor != address(nativo), "nativo cant deposit");
        address to = _actors.rand(toSeed);

        amount = bound(amount, 0, nativo.balanceOf(currentActor));
        if (amount == 0) ghost_zeroTransfers++;

        vm.prank(currentActor);
        nativo.transfer(to, amount);
    }

    function transferFrom(uint256 actorSeed, uint256 fromSeed, uint256 toSeed, bool _approve, uint256 amount)
        public
        useActor(actorSeed)
        countCall("transferFrom")
    {
        require(currentActor != address(nativo), "nativo cant deposit");
        address from = _actors.rand(fromSeed);
        address to = _actors.rand(toSeed);

        amount = bound(amount, 0, nativo.balanceOf(from));

        if (_approve) {
            vm.prank(from);
            nativo.approve(currentActor, amount);
        } else {
            amount = bound(amount, 0, nativo.allowance(from, currentActor));
        }
        if (amount == 0) ghost_zeroTransferFroms++;

        vm.prank(currentActor);
        nativo.transferFrom(from, to, amount);
    }

    function sendFallback(uint256 amount) public createActor countCall("sendFallback") {
        require(currentActor != address(nativo), "nativo cant deposit");
        amount = bound(amount, 0, address(this).balance);
        _pay(currentActor, amount);

        vm.prank(currentActor);
        _pay(address(nativo), amount);

        ghost_depositSum += amount;
    }

    function depositTo(uint256 actorTo, uint256 amount) public createActor countCall("depositTo") {
        require(currentActor != address(nativo), "nativo cant deposit");
        amount = bound(amount, 0, address(this).balance);
        _pay(currentActor, amount);

        vm.prank(currentActor);
        nativo.depositTo{value: amount}(_actors.rand(actorTo));

        ghost_depositSum += amount;
    }

    function withdrawTo(uint256 actorSeed, uint256 actorTo, uint256 amount)
        public
        useActor(actorSeed)
        countCall("withdrawTo")
    {
        require(currentActor != address(nativo), "nativo cant deposit");
        amount = bound(amount, 0, nativo.balanceOf(currentActor));
        if (amount == 0) ghost_zeroWithdrawals++;

        vm.prank(currentActor);
        nativo.withdrawTo(_actors.rand(actorTo), amount);

        vm.prank(_actors.rand(actorTo));
        _pay(address(this), amount);

        ghost_withdrawSum += amount;
    }

    function forcePush(uint256 amount) public countCall("forcePush") {
        amount = bound(amount, 0, address(this).balance);
        new ForcePush{ value: amount }(address(nativo));
        ghost_forcePushSum += amount;
    }

    function forEachActor(function(address) external func) public {
        return _actors.forEach(func);
    }

    function reduceActors(uint256 acc, function(uint256,address) external returns (uint256) func)
        public
        returns (uint256)
    {
        return _actors.reduce(acc, func);
    }

    function actors() external view returns (address[] memory) {
        return _actors.addrs;
    }

    function callSummary() external view {
        console.log("Call summary:");
        console.log("-------------------");
        console.log("deposit", calls["deposit"]);
        console.log("withdraw", calls["withdraw"]);
        console.log("sendFallback", calls["sendFallback"]);
        console.log("approve", calls["approve"]);
        console.log("transfer", calls["transfer"]);
        console.log("transferFrom", calls["transferFrom"]);
        console.log("forcePush", calls["forcePush"]);
        console.log("-------------------");

        console.log("Zero withdrawals:", ghost_zeroWithdrawals);
        console.log("Zero transferFroms:", ghost_zeroTransferFroms);
        console.log("Zero transfers:", ghost_zeroTransfers);
    }

    function _pay(address to, uint256 amount) internal {
        (bool s,) = to.call{value: amount}("");
        require(s, "pay() failed");
    }

    receive() external payable {}
}
