// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (C) 2026 Hirme Labs LLC
pragma solidity ^0.8.33;

import {Test} from "forge-std/Test.sol";
import {U512Math} from "../../src/U512Math.sol";

contract U512BoundaryTest is Test {
    using U512Math for U512Math.U512;

    function u(uint256 lo, uint256 hi) internal pure returns (U512Math.U512 memory) {
        return U512Math.U512({lo: lo, hi: hi});
    }

    function addExternal(U512Math.U512 memory a, U512Math.U512 memory b) external pure returns (U512Math.U512 memory) {
        return a.add(b);
    }

    function divScalarExternal(U512Math.U512 memory a, uint256 d)
        external
        view
        returns (U512Math.U512 memory q, uint256 r)
    {
        return a.div(d);
    }

    function divWideExternal(U512Math.U512 memory a, U512Math.U512 memory b)
        external
        view
        returns (uint256 q, U512Math.U512 memory r)
    {
        return a.div(b);
    }

    function toUintExternal(U512Math.U512 memory a) external pure returns (uint256) {
        return a.toUint256();
    }

    function testEqEqualValues() public pure {
        assertTrue(u(9, 7).eq(u(9, 7)));
    }

    function testEqDifferentLowLimbs() public pure {
        assertFalse(u(9, 7).eq(u(10, 7)));
    }

    function testLtUsesLowLimbWhenHighLimbsMatch() public pure {
        assertTrue(u(9, 7).lt(u(10, 7)));
    }

    function testLtUsesHighLimbBeforeLowLimb() public pure {
        assertTrue(u(type(uint256).max, 1).lt(u(0, 2)));
    }

    function testGtMirrorsLt() public pure {
        assertTrue(u(0, 2).gt(u(type(uint256).max, 1)));
    }

    function testGteIncludesEquality() public pure {
        assertTrue(u(4, 3).gte(u(4, 3)));
    }

    function testAddMaximumValueAndZero() public pure {
        U512Math.U512 memory c = u(type(uint256).max, type(uint256).max).add(u(0, 0));

        assertEq(c.lo, type(uint256).max);
        assertEq(c.hi, type(uint256).max);
    }

    function testAddHighLimbOverflowReverts() public {
        vm.expectRevert(U512Math.U512_Overflow.selector);
        this.addExternal(u(0, type(uint256).max), u(0, 1));
    }

    function testSubEqualValuesReturnsZero() public pure {
        U512Math.U512 memory c = u(99, 42).sub(u(99, 42));

        assertEq(c.lo, 0);
        assertEq(c.hi, 0);
    }

    function testSubMaximumMinusOne() public pure {
        U512Math.U512 memory c = u(type(uint256).max, type(uint256).max).sub(u(1, 0));

        assertEq(c.lo, type(uint256).max - 1);
        assertEq(c.hi, type(uint256).max);
    }

    function testMulScalarByZero() public pure {
        U512Math.U512 memory c = u(99, 42).mul(0);

        assertEq(c.lo, 0);
        assertEq(c.hi, 0);
    }

    function testMulScalarByOne() public pure {
        U512Math.U512 memory c = u(99, 42).mul(1);

        assertEq(c.lo, 99);
        assertEq(c.hi, 42);
    }

    function testMulScalarCrossesLimbBoundary() public pure {
        U512Math.U512 memory c = u(type(uint256).max, 0).mul(2);

        assertEq(c.lo, type(uint256).max - 1);
        assertEq(c.hi, 1);
    }

    function testMulWideByOne() public pure {
        U512Math.U512 memory c = u(99, 42).mul(u(1, 0));

        assertEq(c.lo, 99);
        assertEq(c.hi, 42);
    }

    function testMulWideCrossTermFits() public pure {
        U512Math.U512 memory c = u(0, 1).mul(u(2, 0));

        assertEq(c.lo, 0);
        assertEq(c.hi, 2);
    }

    function testDivScalarByZeroReverts() public {
        vm.expectRevert(U512Math.DivByZero.selector);
        this.divScalarExternal(u(1, 1), 0);
    }

    function testDivScalarByOne() public view {
        U512Math.U512 memory a = u(type(uint256).max, type(uint256).max);

        (U512Math.U512 memory q, uint256 r) = a.div(1);

        assertTrue(q.eq(a));
        assertEq(r, 0);
    }

    function testDivScalarByMaximumDivisor() public view {
        (U512Math.U512 memory q, uint256 r) = u(type(uint256).max, 1).div(type(uint256).max);

        assertEq(q.lo, 2);
        assertEq(q.hi, 0);
        assertEq(r, 1);
    }

    function testDivToUint256Success() public view {
        (uint256 q, uint256 r) = u(1000, 0).divToUint256(64);

        assertEq(q, 15);
        assertEq(r, 40);
    }

    function testDivWideQuotientTooLargeReverts() public {
        vm.expectRevert(U512Math.DivQuotientTooLarge.selector);
        this.divWideExternal(u(0, 1), u(1, 0));
    }

    function testDivUintByWideEqualValues() public pure {
        U512Math.U512 memory divisor = u(type(uint256).max, 0);

        (uint256 q, uint256 r) = U512Math.div(type(uint256).max, divisor);

        assertEq(q, 1);
        assertEq(r, 0);
    }

    function testToUint256Success() public pure {
        assertEq(u(123456, 0).toUint256(), 123456);
    }

    function testToUint256HighLimbReverts() public {
        vm.expectRevert(U512Math.DivQuotientTooLarge.selector);
        this.toUintExternal(u(0, 1));
    }

    function testNeedsExpansionAtMaximumHighLimb() public pure {
        assertTrue(U512Math.needsExpansion(type(uint256).max));
    }

    function testNeedsExpansionAtZeroIsFalse() public pure {
        assertFalse(U512Math.needsExpansion(0));
    }
}
