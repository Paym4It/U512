// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (C) 2026 Hirme Labs LLC
pragma solidity ^0.8.33;

import {Test} from "forge-std/Test.sol";
import {U512Math} from "../../src/U512Math.sol";

contract U512BaselineFuzzTest is Test {
    using U512Math for U512Math.U512;

    function u(uint256 lo, uint256 hi) internal pure returns (U512Math.U512 memory) {
        return U512Math.U512({lo: lo, hi: hi});
    }

    function testFuzzAddSubInvariant(uint256 lo1, uint256 hi1, uint256 lo2, uint256 hi2) public pure {
        U512Math.U512 memory a = u(lo1, hi1);
        U512Math.U512 memory b = u(lo2, hi2);

        uint256 lo;
        uint256 carry;
        uint256 hi;

        unchecked {
            lo = lo1 + lo2;
            carry = lo < lo1 ? 1 : 0;
            hi = hi1 + hi2;
        }

        vm.assume(hi >= hi1);
        vm.assume(type(uint256).max - hi >= carry);

        U512Math.U512 memory c = a.add(b);
        U512Math.U512 memory d = c.sub(b);

        assertTrue(d.eq(a));
    }

    function testFuzzDivIdentity(uint256 lo, uint256 hi, uint256 d) public view {
        vm.assume(d > 0);

        U512Math.U512 memory a = u(lo, hi);
        (U512Math.U512 memory q, uint256 r) = a.div(d);

        U512Math.U512 memory qd = q.mul(d);
        U512Math.U512 memory reconstructed = qd.add(u(r, 0));

        assertTrue(reconstructed.eq(a));
    }
}
