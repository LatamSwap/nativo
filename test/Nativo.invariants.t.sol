// SPDX-License-Identifier: GPL-3.0-or-later
// Based on https://github.com/horsefacts/weth-invariant-testing
// @author horsefacts
pragma solidity >=0.8.10;

import "forge-std/Test.sol";
import {Handler, ETH_SUPPLY} from "./handlers/Handler.sol";

import {Nativo} from "src/Nativo.sol";

contract NativoInvariants is Test {
    Nativo public nativo;
    Handler public handler;

    function setUp() public {
        // name and symbol depend on the blockchain we are deploying
        nativo = new Nativo("Wrapped Nativo crypto", "Wany");
        handler = new Handler(nativo);

        bytes4[] memory selectors = new bytes4[](10);
        selectors[0] = Handler.deposit.selector;
        selectors[1] = Handler.withdraw.selector;
        selectors[2] = Handler.sendFallback.selector;
        selectors[3] = Handler.approve.selector;
        selectors[4] = Handler.transfer.selector;
        selectors[5] = Handler.transferFrom.selector;
        selectors[6] = Handler.depositTo.selector;
        selectors[7] = Handler.withdrawTo.selector;
        selectors[8] = Handler.withdrawAll.selector;
        selectors[9] = Handler.withdrawAllTo.selector;

        //selectors[6] = Handler.forcePush.selector;

        targetSelector(FuzzSelector({addr: address(handler), selectors: selectors}));

        targetContract(address(handler));
    }

    // ETH can only be wrapped into Nativo, Nativo can only
    // be unwrapped back into ETH. The sum of the Handler's
    // ETH balance plus the Nativo totalSupply() should always
    // equal the total ETH_SUPPLY.
    function invariant_conservationOfETH() public {
        if (ETH_SUPPLY != address(handler).balance + nativo.totalSupply()) {
            console.log("ETH_SUPPLY", ETH_SUPPLY);
            console.log("address(handler).balance", address(handler).balance);
            console.log("nativo.totalSupply()", nativo.totalSupply());
        }

        assertEq(ETH_SUPPLY, address(handler).balance + nativo.totalSupply());
    }

    // The Nativo contract's Ether balance should always be
    // at least as much as the sum of individual deposits
    function invariant_solvencyDeposits() public {
        assertEq(
            address(nativo).balance,
            handler.ghost_depositSum() + handler.ghost_forcePushSum() - handler.ghost_withdrawSum()
        );
    }

    // The Nativo contract's Ether balance should always be
    // at least as much as the sum of individual balances
    function invariant_solvencyBalances() public {
        uint256 sumOfBalances = handler.reduceActors(0, this.accumulateBalance);
        assertEq(address(nativo).balance - handler.ghost_forcePushSum(), sumOfBalances);
    }

    function invariant_internalData() public {
        assertEq(nativo.treasury(), address(this));
        assertEq(nativo.manager(), address(this));
    }

    function accumulateBalance(uint256 balance, address caller) external view returns (uint256) {
        return balance + nativo.balanceOf(caller);
    }

    // No individual account balance can exceed the
    // Nativo totalSupply().
    function invariant_depositorBalances() public {
        handler.forEachActor(this.assertAccountBalanceLteTotalSupply);
    }

    function assertAccountBalanceLteTotalSupply(address account) external {
        assertLe(nativo.balanceOf(account), nativo.totalSupply());
    }

    function invariant_callSummary() public view {
        handler.callSummary();
    }
}
