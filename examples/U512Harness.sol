// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (C) 2026 Hirme Labs LLC
pragma solidity ^0.8.33;

import {U512Math} from "../src/U512Math.sol";

/// @notice Deployable demonstration wrapper for the internal U512 library.
/// @dev This contract is testing infrastructure, not a required production
///      deployment and not a protocol component.
contract U512Harness {
    using U512Math for U512Math.U512;

    event U512ExpansionWarning(bytes32 indexed tag, uint256 hi, uint256 threshold);

    function compare(uint256 loA, uint256 hiA, uint256 loB, uint256 hiB)
        external
        pure
        returns (bool equal, bool less, bool greater, bool greaterOrEqual)
    {
        U512Math.U512 memory a = U512Math.U512({lo: loA, hi: hiA});
        U512Math.U512 memory b = U512Math.U512({lo: loB, hi: hiB});

        return (a.eq(b), a.lt(b), a.gt(b), a.gte(b));
    }

    function add(uint256 loA, uint256 hiA, uint256 loB, uint256 hiB) external pure returns (uint256 lo, uint256 hi) {
        U512Math.U512 memory result = U512Math.U512({lo: loA, hi: hiA}).add(U512Math.U512({lo: loB, hi: hiB}));

        return (result.lo, result.hi);
    }

    function sub(uint256 loA, uint256 hiA, uint256 loB, uint256 hiB) external pure returns (uint256 lo, uint256 hi) {
        U512Math.U512 memory result = U512Math.U512({lo: loA, hi: hiA}).sub(U512Math.U512({lo: loB, hi: hiB}));

        return (result.lo, result.hi);
    }

    function mul256(uint256 a, uint256 b) external pure returns (uint256 lo, uint256 hi) {
        U512Math.U512 memory result = U512Math.mul256(a, b);

        return (result.lo, result.hi);
    }

    function mulScalar(uint256 loA, uint256 hiA, uint256 scalar) external pure returns (uint256 lo, uint256 hi) {
        U512Math.U512 memory result = U512Math.U512({lo: loA, hi: hiA}).mul(scalar);

        return (result.lo, result.hi);
    }

    function mulWide(uint256 loA, uint256 hiA, uint256 loB, uint256 hiB)
        external
        pure
        returns (uint256 lo, uint256 hi)
    {
        U512Math.U512 memory result = U512Math.U512({lo: loA, hi: hiA}).mul(U512Math.U512({lo: loB, hi: hiB}));

        return (result.lo, result.hi);
    }

    function divScalar(uint256 loA, uint256 hiA, uint256 divisor)
        external
        view
        returns (uint256 qLo, uint256 qHi, uint256 remainder)
    {
        (U512Math.U512 memory q, uint256 r) = U512Math.U512({lo: loA, hi: hiA}).div(divisor);

        return (q.lo, q.hi, r);
    }

    function divScalarToUint(uint256 loA, uint256 hiA, uint256 divisor)
        external
        view
        returns (uint256 quotient, uint256 remainder)
    {
        return U512Math.U512({lo: loA, hi: hiA}).divToUint256(divisor);
    }

    function divWide(uint256 loA, uint256 hiA, uint256 loB, uint256 hiB)
        external
        view
        returns (uint256 quotient, uint256 rLo, uint256 rHi)
    {
        (uint256 q, U512Math.U512 memory r) = U512Math.U512({lo: loA, hi: hiA}).div(U512Math.U512({lo: loB, hi: hiB}));

        return (q, r.lo, r.hi);
    }

    function divUintByWide(uint256 value, uint256 divisorLo, uint256 divisorHi)
        external
        pure
        returns (uint256 quotient, uint256 remainder)
    {
        return U512Math.div(value, U512Math.U512({lo: divisorLo, hi: divisorHi}));
    }

    function toUint(uint256 lo, uint256 hi) external pure returns (uint256) {
        return U512Math.U512({lo: lo, hi: hi}).toUint256();
    }

    function needsExpansion(uint256 hi) external pure returns (bool) {
        return U512Math.needsExpansion(hi);
    }

    function addAndWarn(bytes32 tag, uint256 loA, uint256 hiA, uint256 loB, uint256 hiB)
        external
        returns (uint256 lo, uint256 hi)
    {
        U512Math.U512 memory result = U512Math.U512({lo: loA, hi: hiA}).add(U512Math.U512({lo: loB, hi: hiB}));

        if (U512Math.needsExpansion(result.hi)) {
            emit U512ExpansionWarning(tag, result.hi, U512Math.HI_WARNING_THRESHOLD);
        }

        return (result.lo, result.hi);
    }
}
