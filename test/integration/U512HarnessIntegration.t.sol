// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (C) 2026 Hirme Labs LLC
pragma solidity ^0.8.33;

import {Test} from "forge-std/Test.sol";
import {Vm} from "forge-std/Vm.sol";
import {U512Math} from "../../src/U512Math.sol";
import {U512Harness} from "../../examples/U512Harness.sol";

contract U512HarnessIntegrationTest is Test {
    U512Harness internal harness;

    bytes32 internal constant TAG = keccak256("U512_TEST");

    event U512ExpansionWarning(bytes32 indexed tag, uint256 hi, uint256 threshold);

    function setUp() public {
        harness = new U512Harness();
    }

    function testHarnessDeploymentHasCode() public view {
        assertGt(address(harness).code.length, 0);
    }

    function testHarnessComparison() public view {
        (bool equal, bool less, bool greater, bool greaterOrEqual) = harness.compare(9, 7, 10, 7);

        assertFalse(equal);
        assertTrue(less);
        assertFalse(greater);
        assertFalse(greaterOrEqual);
    }

    function testHarnessAdditionPreservesLimbOrder() public view {
        (uint256 lo, uint256 hi) = harness.add(type(uint256).max, 7, 1, 9);

        assertEq(lo, 0);
        assertEq(hi, 17);
    }

    function testHarnessDivisionExercisesModExp() public view {
        (uint256 qLo, uint256 qHi, uint256 remainder) = harness.divScalar(0, 1, 3);

        assertEq(qLo, type(uint256).max / 3);
        assertEq(qHi, 0);
        assertEq(remainder, 1);
    }

    function testHarnessWideDivision() public view {
        (uint256 quotient, uint256 remainderLo, uint256 remainderHi) =
            harness.divWide(type(uint256).max, type(uint256).max, 0, 1);

        assertEq(quotient, type(uint256).max);
        assertEq(remainderLo, type(uint256).max);
        assertEq(remainderHi, 0);
    }

    function testHarnessEmitsCanonicalWarningAtThreshold() public {
        uint256 threshold = U512Math.HI_WARNING_THRESHOLD;

        vm.expectEmit(true, false, false, true, address(harness));
        emit U512ExpansionWarning(TAG, threshold, threshold);

        harness.addAndWarn(TAG, 0, threshold, 0, 0);
    }

    function testHarnessDoesNotEmitWarningBelowThreshold() public {
        vm.recordLogs();

        harness.addAndWarn(TAG, 0, U512Math.HI_WARNING_THRESHOLD - 1, 0, 0);

        Vm.Log[] memory entries = vm.getRecordedLogs();

        assertEq(entries.length, 0);
    }

    function testHarnessBubblesOverflow() public {
        vm.expectRevert(U512Math.U512_Overflow.selector);

        harness.add(type(uint256).max, type(uint256).max, 1, 0);
    }
}
