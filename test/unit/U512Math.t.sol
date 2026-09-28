// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (C) 2026 Hirme Labs LLC
pragma solidity ^0.8.33;

import {Test} from "forge-std/Test.sol";
import {U512Math} from "../../src/U512Math.sol";

contract U512MathTest is Test {
    using U512Math for U512Math.U512;

    function u(uint256 lo, uint256 hi) internal pure returns (U512Math.U512 memory) {
        return U512Math.U512({lo: lo, hi: hi});
    }

    function divToUint256External(U512Math.U512 memory a, uint256 d) external view returns (uint256 q256, uint256 r) {
        return a.divToUint256(d);
    }

    function addExternal(U512Math.U512 memory a, U512Math.U512 memory b)
        external
        pure
        returns (U512Math.U512 memory c)
    {
        return a.add(b);
    }

    function subExternal(U512Math.U512 memory a, U512Math.U512 memory b)
        external
        pure
        returns (U512Math.U512 memory c)
    {
        return a.sub(b);
    }

    function mulExternal(U512Math.U512 memory a, uint256 b) external pure returns (U512Math.U512 memory c) {
        return a.mul(b);
    }

    /*//////////////////////////////////////////////////////////////
                            BASIC ADD/SUB
    //////////////////////////////////////////////////////////////*/

    function testAddNoCarry() public pure {
        U512Math.U512 memory a = u(5, 1);
        U512Math.U512 memory b = u(7, 3);
        U512Math.U512 memory c = a.add(b);
        assertEq(c.lo, 12);
        assertEq(c.hi, 4);
    }

    function testAddWithCarry() public pure {
        U512Math.U512 memory a = u(type(uint256).max, 1);
        U512Math.U512 memory b = u(1, 2);
        U512Math.U512 memory c = a.add(b);
        assertEq(c.lo, 0);
        assertEq(c.hi, 4);
    }

    function testAddOverflowWithCarryReverts() public {
        U512Math.U512 memory a = u(14, type(uint256).max);
        U512Math.U512 memory b = u(type(uint256).max - 3, type(uint256).max);
        vm.expectRevert(U512Math.U512_Overflow.selector);
        this.addExternal(a, b);
    }

    function testAddAllowsCrossingIntoWarningZone() public pure {
        U512Math.U512 memory a = u(type(uint256).max, U512Math.HI_WARNING_THRESHOLD - 1);
        U512Math.U512 memory b = u(1, 0);
        U512Math.U512 memory c = a.add(b);
        assertEq(c.lo, 0);
        assertEq(c.hi, U512Math.HI_WARNING_THRESHOLD);
        assertTrue(U512Math.needsExpansion(c.hi));
    }

    function testSubNoBorrow() public pure {
        U512Math.U512 memory a = u(10, 5);
        U512Math.U512 memory b = u(3, 2);
        U512Math.U512 memory c = a.sub(b);
        assertEq(c.lo, 7);
        assertEq(c.hi, 3);
    }

    function testSubWithBorrow() public pure {
        U512Math.U512 memory a = u(0, 5);
        U512Math.U512 memory b = u(1, 2);
        U512Math.U512 memory c = a.sub(b);
        assertEq(c.lo, type(uint256).max);
        assertEq(c.hi, 2);
    }

    function testSubUnderflowReverts() public {
        U512Math.U512 memory a = u(0, 0);
        U512Math.U512 memory b = u(1, 0);
        vm.expectRevert(U512Math.U512_Underflow.selector);
        this.subExternal(a, b);
    }

    /*//////////////////////////////////////////////////////////////
                          MULTIPLICATION
    //////////////////////////////////////////////////////////////*/

    function testMul256Simple() public pure {
        U512Math.U512 memory p = U512Math.mul256(3, 4);
        assertEq(p.lo, 12);
        assertEq(p.hi, 0);
    }

    function testMul256OverflowIntoHi() public pure {
        uint256 a = type(uint256).max;
        U512Math.U512 memory p = U512Math.mul256(a, 2);
        assertEq(p.lo, type(uint256).max - 1);
        assertEq(p.hi, 1);
    }

    function testMul512By256() public pure {
        U512Math.U512 memory a = u(5, 3);
        U512Math.U512 memory c = a.mul(7);
        // (3*2^256 + 5)*7 = 21*2^256 + 35
        assertEq(c.lo, 35);
        assertEq(c.hi, 21);
    }

    function testMulOverflowReverts() public {
        U512Math.U512 memory a = u(0, type(uint256).max);
        vm.expectRevert(U512Math.U512_Overflow.selector);
        this.mulExternal(a, type(uint256).max);
    }

    /*//////////////////////////////////////////////////////////////
                             DIVISION
    //////////////////////////////////////////////////////////////*/

    function testDivSimple() public view {
        U512Math.U512 memory a = u(100, 0);
        (U512Math.U512 memory q, uint256 r) = a.div(7);
        assertEq(q.lo, 14);
        assertEq(q.hi, 0);
        assertEq(r, 2);
    }

    function testDivWithHi() public view {
        // (1*2^256 + 0) / 2 = 2^255
        U512Math.U512 memory a = u(0, 1);
        (U512Math.U512 memory q, uint256 r) = a.div(2);
        assertEq(q.lo, uint256(1) << 255);
        assertEq(q.hi, 0);
        assertEq(r, 0);
    }

    function testDivToUint256RevertsWhenTooLarge() public {
        U512Math.U512 memory a = u(0, 1);
        vm.expectRevert(U512Math.DivQuotientTooLarge.selector);
        this.divToUint256External(a, 1);
    }

    /*//////////////////////////////////////////////////////////////
                         EXPANSION WARNING
    //////////////////////////////////////////////////////////////*/

    function testNeedsExpansionThreshold() public pure {
        uint256 t = U512Math.HI_WARNING_THRESHOLD;
        assertFalse(U512Math.needsExpansion(t - 1));
        assertTrue(U512Math.needsExpansion(t));
        assertTrue(U512Math.needsExpansion(t + 1));
    }
}
