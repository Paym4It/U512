// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (C) 2026 Hirme Labs LLC
pragma solidity ^0.8.33;

import {Test} from "forge-std/Test.sol";
import {U512Math} from "../../src/U512Math.sol";

contract U512ExtendedFuzzTest is Test {
    using U512Math for U512Math.U512;

    function u(uint256 lo, uint256 hi) internal pure returns (U512Math.U512 memory) {
        return U512Math.U512({lo: lo, hi: hi});
    }

    function testFuzzComparisonConsistency(uint256 loA, uint256 hiA, uint256 loB, uint256 hiB) public pure {
        U512Math.U512 memory a = u(loA, hiA);
        U512Math.U512 memory b = u(loB, hiB);

        bool expectedEq = hiA == hiB && loA == loB;
        bool expectedLt = hiA < hiB || (hiA == hiB && loA < loB);

        assertEq(a.eq(b), expectedEq);
        assertEq(a.lt(b), expectedLt);
        assertEq(a.gt(b), !expectedEq && !expectedLt);
        assertEq(a.gte(b), !expectedLt);
    }

    function testFuzzSubAddRoundTrip(uint256 loA, uint256 hiA, uint256 loB, uint256 hiB) public pure {
        U512Math.U512 memory a = u(loA, hiA);
        U512Math.U512 memory b = u(loB, hiB);

        vm.assume(!a.lt(b));

        U512Math.U512 memory difference = a.sub(b);
        U512Math.U512 memory reconstructed = difference.add(b);

        assertTrue(reconstructed.eq(a));
    }

    function testFuzzMul256Congruence(uint256 a, uint256 b) public pure {
        U512Math.U512 memory product = U512Math.mul256(a, b);

        uint256 nativeLow;

        unchecked {
            nativeLow = a * b;
        }

        assertEq(product.lo, nativeLow);

        uint256 modulus = type(uint256).max;
        uint256 expectedModulo = mulmod(a, b, modulus);
        uint256 actualModulo = addmod(product.lo, product.hi, modulus);

        assertEq(actualModulo, expectedModulo);
    }

    function testFuzzMulScalarZeroAndOne(uint256 lo, uint256 hi) public pure {
        U512Math.U512 memory a = u(lo, hi);
        U512Math.U512 memory zero = a.mul(0);
        U512Math.U512 memory identity = a.mul(1);

        assertEq(zero.lo, 0);
        assertEq(zero.hi, 0);
        assertTrue(identity.eq(a));
    }

    function testFuzzDivUintByWideMatchesNative(uint256 value, uint256 divisor) public pure {
        vm.assume(divisor > 0);

        (uint256 q, uint256 r) = U512Math.div(value, u(divisor, 0));

        assertEq(q, value / divisor);
        assertEq(r, value % divisor);
    }

    function testFuzzDivWideDenominatorGreater(uint256 loA, uint256 hiA, uint256 loB, uint256 hiB) public view {
        U512Math.U512 memory a = u(loA, hiA);
        U512Math.U512 memory b = u(loB, hiB);

        vm.assume(b.lo != 0 || b.hi != 0);
        vm.assume(a.lt(b));

        (uint256 q, U512Math.U512 memory r) = a.div(b);

        assertEq(q, 0);
        assertTrue(r.eq(a));
    }

    function testFuzzToUintWhenHighIsZero(uint256 lo) public pure {
        assertEq(u(lo, 0).toUint256(), lo);
    }

    function testFuzzWarningPredicate(uint256 hi) public pure {
        bool expected = hi >= U512Math.HI_WARNING_THRESHOLD;

        assertEq(U512Math.needsExpansion(hi), expected);
    }
}
