// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (C) 2026 Hirme Labs LLC
pragma solidity ^0.8.33;

import {Test} from "forge-std/Test.sol";
import {StdInvariant} from "forge-std/StdInvariant.sol";
import {U512Math} from "../../src/U512Math.sol";

contract U512AccumulatorHandler {
    using U512Math for U512Math.U512;

    U512Math.U512 private current;

    uint256 public shadowLo;
    uint256 public shadowHi;
    uint256 public operationCount;

    function addScalar(uint256 value) external {
        uint256 nextLo;
        uint256 nextHi = shadowHi;

        unchecked {
            nextLo = shadowLo + value;

            if (nextLo < shadowLo) {
                if (shadowHi == type(uint256).max) {
                    return;
                }

                nextHi = shadowHi + 1;
            }
        }

        U512Math.U512 memory currentValue = U512Math.U512({lo: current.lo, hi: current.hi});

        current = currentValue.add(U512Math.U512({lo: value, hi: 0}));

        shadowLo = nextLo;
        shadowHi = nextHi;

        unchecked {
            operationCount++;
        }
    }

    function subScalar(uint256 value) external {
        if (shadowHi == 0 && value > shadowLo) {
            return;
        }

        uint256 borrow = shadowLo < value ? 1 : 0;
        uint256 nextLo;
        uint256 nextHi;

        unchecked {
            nextLo = shadowLo - value;
            nextHi = shadowHi - borrow;
        }

        U512Math.U512 memory currentValue = U512Math.U512({lo: current.lo, hi: current.hi});

        current = currentValue.sub(U512Math.U512({lo: value, hi: 0}));

        shadowLo = nextLo;
        shadowHi = nextHi;

        unchecked {
            operationCount++;
        }
    }

    function state() external view returns (uint256 lo, uint256 hi) {
        return (current.lo, current.hi);
    }
}

contract U512InvariantTest is StdInvariant, Test {
    using U512Math for U512Math.U512;

    U512AccumulatorHandler internal handler;

    function setUp() public {
        handler = new U512AccumulatorHandler();
        targetContract(address(handler));
    }

    function invariantStateMatchesIndependentShadow() public view {
        (uint256 lo, uint256 hi) = handler.state();

        assertEq(lo, handler.shadowLo());
        assertEq(hi, handler.shadowHi());
    }

    function invariantWarningPredicateMatchesThreshold() public view {
        (, uint256 hi) = handler.state();

        bool expected = hi >= U512Math.HI_WARNING_THRESHOLD;

        assertEq(U512Math.needsExpansion(hi), expected);
    }

    function invariantToUint256WhenHighIsZero() public view {
        (uint256 lo, uint256 hi) = handler.state();

        if (hi == 0) {
            U512Math.U512 memory value = U512Math.U512({lo: lo, hi: hi});

            assertEq(value.toUint256(), lo);
        }
    }
}
