// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (C) 2026 Hirme Labs LLC
pragma solidity ^0.8.33;

import {Test} from "forge-std/Test.sol";
import {U512Math} from "../../src/U512Math.sol";

contract U512MathExtendedTest is Test {
    using U512Math for U512Math.U512;

    function u(uint256 lo, uint256 hi) internal pure returns (U512Math.U512 memory) {
        return U512Math.U512({lo: lo, hi: hi});
    }

    function mul512External(U512Math.U512 memory a, U512Math.U512 memory b)
        external
        pure
        returns (U512Math.U512 memory c)
    {
        return a.mul(b);
    }

    function div512External(U512Math.U512 memory a, U512Math.U512 memory b)
        external
        view
        returns (uint256 q, U512Math.U512 memory r)
    {
        return a.div(b);
    }

    function div256By512External(uint256 a, U512Math.U512 memory b) external pure returns (uint256 q, uint256 r) {
        return U512Math.div(a, b);
    }

    function testMul512By512Simple() public pure {
        U512Math.U512 memory a = u(5, 0);
        U512Math.U512 memory b = u(7, 0);
        U512Math.U512 memory c = a.mul(b);
        assertEq(c.lo, 35);
        assertEq(c.hi, 0);
    }

    function testMul512By512WithCrossTerms() public {
        // (3*2^256 + 2) * (4*2^256 + 1)
        // = 11*2^256 + 2  (the 12*2^512 term overflows and should be rejected if present)
        U512Math.U512 memory a = u(2, 3);
        U512Math.U512 memory b = u(1, 4);
        vm.expectRevert(U512Math.U512_Overflow.selector);
        this.mul512External(a, b);
    }

    function testMul512By512OverflowReverts() public {
        U512Math.U512 memory a = u(type(uint256).max, type(uint256).max);
        U512Math.U512 memory b = u(type(uint256).max, type(uint256).max);
        vm.expectRevert(U512Math.U512_Overflow.selector);
        this.mul512External(a, b);
    }

    function testDiv512By512Simple() public view {
        U512Math.U512 memory a = u(100, 0);
        U512Math.U512 memory b = u(7, 0);
        (uint256 q, U512Math.U512 memory r) = a.div(b);
        assertEq(q, 14);
        assertEq(r.lo, 2);
        assertEq(r.hi, 0);
    }

    function testDiv512By512DenominatorGreater() public view {
        U512Math.U512 memory a = u(50, 0);
        U512Math.U512 memory b = u(100, 0);
        (uint256 q, U512Math.U512 memory r) = a.div(b);
        assertEq(q, 0);
        assertEq(r.lo, 50);
        assertEq(r.hi, 0);
    }

    function testDiv512By512CorrectsOverlargeEstimateWithoutOverflow() public view {
        U512Math.U512 memory a = u(type(uint256).max, type(uint256).max);
        U512Math.U512 memory b = u(type(uint256).max, 1);

        (uint256 q, U512Math.U512 memory r) = a.div(b);

        assertEq(q, uint256(1) << 255);
        assertEq(r.lo, (uint256(1) << 255) - 1);
        assertEq(r.hi, 0);
    }

    function testDiv512By512ByZeroReverts() public {
        U512Math.U512 memory a = u(10, 1);
        U512Math.U512 memory b = u(0, 0);
        vm.expectRevert(U512Math.DivByZero.selector);
        this.div512External(a, b);
    }

    function testDiv256By512WhenDenominatorHiNonZero() public pure {
        // b >= 2^256 => quotient is 0, remainder is a.
        U512Math.U512 memory b = u(0, 1);
        (uint256 q, uint256 r) = U512Math.div(12345, b);
        assertEq(q, 0);
        assertEq(r, 12345);
    }

    function testDiv256By512NormalCase() public pure {
        U512Math.U512 memory b = u(7, 0);
        (uint256 q, uint256 r) = U512Math.div(100, b);
        assertEq(q, 14);
        assertEq(r, 2);
    }

    function testDiv256By512ByZeroReverts() public {
        U512Math.U512 memory b = u(0, 0);
        vm.expectRevert(U512Math.DivByZero.selector);
        this.div256By512External(42, b);
    }
}
