// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (C) 2026 Hirme Labs LLC
pragma solidity ^0.8.33;

import {Test} from "forge-std/Test.sol";
import {U512Math} from "../../src/U512Math.sol";

contract U512ReferenceVectorsTest is Test {
    using U512Math for U512Math.U512;

    function u(uint256 lo, uint256 hi) internal pure returns (U512Math.U512 memory) {
        return U512Math.U512({lo: lo, hi: hi});
    }

    function testVectorAddCarry() public pure {
        U512Math.U512 memory c = u(type(uint256).max, 7).add(u(1, 9));

        assertEq(c.lo, 0);
        assertEq(c.hi, 17);
    }

    function testVectorSubBorrow() public pure {
        U512Math.U512 memory c = u(0, 17).sub(u(1, 9));

        assertEq(c.lo, type(uint256).max);
        assertEq(c.hi, 7);
    }

    function testVectorMulMaximumUint256Squared() public pure {
        U512Math.U512 memory p = U512Math.mul256(type(uint256).max, type(uint256).max);

        assertEq(p.lo, 1);
        assertEq(p.hi, type(uint256).max - 1);
    }

    function testVectorMulScalarAcrossBothLimbs() public pure {
        U512Math.U512 memory p = u(type(uint256).max, 2).mul(3);

        assertEq(p.lo, type(uint256).max - 2);
        assertEq(p.hi, 8);
    }

    function testVectorDivideTwoTo256ByThree() public view {
        (U512Math.U512 memory q, uint256 r) = u(0, 1).div(3);

        assertEq(q.lo, type(uint256).max / 3);
        assertEq(q.hi, 0);
        assertEq(r, 1);
    }

    function testVectorDivideMaximumU512ByMaximumUint256() public view {
        U512Math.U512 memory maximum = u(type(uint256).max, type(uint256).max);

        (U512Math.U512 memory q, uint256 r) = maximum.div(type(uint256).max);

        assertEq(q.lo, 1);
        assertEq(q.hi, 1);
        assertEq(r, 0);
    }

    function testVectorDivideMaximumU512ByTwoTo256() public view {
        U512Math.U512 memory maximum = u(type(uint256).max, type(uint256).max);

        (uint256 q, U512Math.U512 memory r) = maximum.div(u(0, 1));

        assertEq(q, type(uint256).max);
        assertEq(r.lo, type(uint256).max);
        assertEq(r.hi, 0);
    }
}
