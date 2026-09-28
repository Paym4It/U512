// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (C) 2026 Hirme Labs LLC
pragma solidity ^0.8.33;

/// @title U512Math
/// @notice Safe arithmetic for unsigned 512-bit integers represented as (hi, lo):
///         X = hi * 2^256 + lo
/// @dev Designed as reusable on-chain arithmetic with no protocol-specific state or policy.
///      - No silent truncation: operations revert on true overflow/underflow.
///      - Includes 512/256 division using a full-precision technique (uses modexp precompile for 2^256 mod d).
///      - Includes checked 512*512 -> 512 (reverts if product would exceed 512 bits).
///      - Includes checked 512/512 -> uint256 (reverts if quotient would exceed uint256).
library U512Math {
    struct U512 {
        uint256 lo;
        uint256 hi;
    }

    // Early warning threshold for entering the high-range zone of the hi limb.
    uint256 constant HI_WARNING_THRESHOLD = 0x7000000000000000000000000000000000000000000000000000000000000000;

    /// @notice Canonical mathematical warning for U512 accumulators entering the configured high-range zone.
    /// @dev Libraries cannot emit events themselves; consuming contracts should emit this when needsExpansion(x.hi) is true
    ///      and should report HI_WARNING_THRESHOLD as the emitted threshold value.
    event U512ExpansionWarning(bytes32 indexed tag, uint256 hi, uint256 threshold);

    error U512_Underflow();
    error U512_Overflow();
    error DivByZero();
    error DivQuotientTooLarge(); // quotient does not fit into uint256 (when a uint256 quotient is required)
    error ModExpFailed();

    /*//////////////////////////////////////////////////////////////
                               COMPARISON
    //////////////////////////////////////////////////////////////*/

    function eq(U512 memory a, U512 memory b) internal pure returns (bool) {
        return a.hi == b.hi && a.lo == b.lo;
    }

    function lt(U512 memory a, U512 memory b) internal pure returns (bool) {
        return (a.hi < b.hi) || (a.hi == b.hi && a.lo < b.lo);
    }

    function gt(U512 memory a, U512 memory b) internal pure returns (bool) {
        return lt(b, a);
    }

    function gte(U512 memory a, U512 memory b) internal pure returns (bool) {
        return !lt(a, b);
    }

    /*//////////////////////////////////////////////////////////////
                                 ADD/SUB
    //////////////////////////////////////////////////////////////*/

    function add(U512 memory a, U512 memory b) internal pure returns (U512 memory c) {
        unchecked {
            uint256 lo = a.lo + b.lo;
            uint256 carry = (lo < a.lo) ? 1 : 0;
            uint256 hi = a.hi + b.hi;

            // Detect true overflow in the hi limb; entering the warning zone is still valid and must not revert.
            if (hi < a.hi) revert U512_Overflow();
            uint256 hiWithCarry = hi + carry;
            if (hiWithCarry < hi) revert U512_Overflow();

            c = U512(lo, hiWithCarry);
        }
    }

    function sub(U512 memory a, U512 memory b) internal pure returns (U512 memory c) {
        if (lt(a, b)) revert U512_Underflow();
        unchecked {
            uint256 borrow = (a.lo < b.lo) ? 1 : 0;
            c.lo = a.lo - b.lo;
            c.hi = a.hi - b.hi - borrow;
        }
    }

    /*//////////////////////////////////////////////////////////////
                         FULL MUL: 256 x 256 -> 512
    //////////////////////////////////////////////////////////////*/

    /// @notice Full precision multiplication of two uint256 values, returning a 512-bit product.
    function mul256(uint256 a, uint256 b) internal pure returns (U512 memory p) {
        unchecked {
            uint256 lo = a * b;
            // mm = (a*b) mod (2^256-1)
            uint256 mm = mulmod(a, b, type(uint256).max);
            uint256 hi = mm - lo;
            if (mm < lo) hi -= 1;
            p = U512(lo, hi);
        }
    }

    /*//////////////////////////////////////////////////////////////
                         MUL: 512 x 256 -> 512 (checked)
    //////////////////////////////////////////////////////////////*/

    /// @notice Multiply a 512-bit number by a 256-bit scalar, returning a 512-bit result.
    /// @dev Reverts if the true product would exceed 512 bits.
    function mul(U512 memory a, uint256 b) internal pure returns (U512 memory c) {
        (bool ok, U512 memory product) = _tryMul(a, b);
        if (!ok) revert U512_Overflow();
        return product;
    }

    function _tryMul(U512 memory a, uint256 b) private pure returns (bool ok, U512 memory c) {
        if (b == 0) return (true, U512(0, 0));
        unchecked {
            // (a.hi*2^256 + a.lo) * b = (a.lo*b) + (a.hi*b)*2^256
            U512 memory p0 = mul256(a.lo, b); // 512
            U512 memory p1 = mul256(a.hi, b); // 512

            // p1 contributes: low limb to result.hi, high limb would exceed 512 bits
            if (p1.hi != 0) return (false, U512(0, 0));

            uint256 hi = p0.hi + p1.lo;
            if (hi < p0.hi) return (false, U512(0, 0));

            return (true, U512(p0.lo, hi));
        }
    }

    /*//////////////////////////////////////////////////////////////
                         MUL: 512 x 512 -> 512 (checked)
    //////////////////////////////////////////////////////////////*/

    /// @notice Multiply two 512-bit numbers, returning a 512-bit result.
    /// @dev Reverts if the true product would exceed 512 bits.
    function mul(U512 memory a, U512 memory b) internal pure returns (U512 memory c) {
        // a*b = (a.lo + a.hi*2^256) * (b.lo + b.hi*2^256)
        //     = a.lo*b.lo
        //       + (a.lo*b.hi + a.hi*b.lo)*2^256
        //       + (a.hi*b.hi)*2^512
        //
        // To fit in 512 bits:
        //   - a.hi*b.hi must be 0
        //   - high parts of cross products (a.lo*b.hi and a.hi*b.lo) must be 0 (since they are shifted by 256)
        unchecked {
            U512 memory p00 = mul256(a.lo, b.lo);
            U512 memory p01 = mul256(a.lo, b.hi);
            U512 memory p10 = mul256(a.hi, b.lo);
            U512 memory p11 = mul256(a.hi, b.hi);

            // Any contribution to 2^512 or higher overflows 512-bit result
            if (p11.hi != 0 || p11.lo != 0) revert U512_Overflow();
            // Cross terms are shifted by 256; their high limbs would land beyond 512
            if (p01.hi != 0 || p10.hi != 0) revert U512_Overflow();

            // Result:
            // lo = p00.lo
            // hi = p00.hi + p01.lo + p10.lo  (checked for overflow)
            uint256 hi = p00.hi + p01.lo;
            if (hi < p00.hi) revert U512_Overflow();
            uint256 hi2 = hi + p10.lo;
            if (hi2 < hi) revert U512_Overflow();

            c = U512(p00.lo, hi2);
        }
    }

    /*//////////////////////////////////////////////////////////////
                           DIVISION: 512 / 256
    //////////////////////////////////////////////////////////////*/

    /// @notice Divide a 512-bit unsigned integer by a 256-bit unsigned integer.
    /// @return q Quotient as U512.
    /// @return r Remainder as uint256.
    function div(U512 memory a, uint256 d) internal view returns (U512 memory q, uint256 r) {
        if (d == 0) revert DivByZero();
        unchecked {
            // Divide high limb:
            uint256 qHi = a.hi / d;
            uint256 remHi = a.hi % d;

            // Divide (remHi*2^256 + a.lo) by d with remHi < d so qLo fits uint256.
            (uint256 qLo, uint256 rem) = _div512by256(remHi, a.lo, d);

            q = U512(qLo, qHi);
            r = rem;
        }
    }

    /// @notice Divide a 512-bit number by a uint256 and require the quotient fits uint256 (q.hi == 0).
    function divToUint256(U512 memory a, uint256 d) internal view returns (uint256 q256, uint256 r) {
        (U512 memory q, uint256 rem) = div(a, d);
        if (q.hi != 0) revert DivQuotientTooLarge();
        return (q.lo, rem);
    }

    /// @dev Core helper: divide N=(hi*2^256+lo) by d, with precondition hi < d.
    ///      Returns (q, r) where q fits uint256.
    function _div512by256(uint256 hi, uint256 lo, uint256 d) private view returns (uint256 q, uint256 r) {
        // Required so that the quotient fits in 256 bits.
        if (!(hi < d)) revert DivQuotientTooLarge();

        unchecked {
            // r = (hi*2^256 + lo) mod d = (hi*(2^256 mod d) + lo) mod d
            uint256 pow = _pow2_256_mod(d);
            r = addmod(mulmod(hi, pow, d), lo % d, d);

            // exact quotient for (hi*2^256 + lo - r) / d
            q = _exactDiv512By256(hi, lo, d, r);
        }
    }

    /// @dev Computes 2^256 mod m via modexp precompile (0x05).
    function _pow2_256_mod(uint256 m) private view returns (uint256 out) {
        if (m == 1) return 0;
        bytes memory input = new bytes(32 * 6);
        assembly {
            mstore(add(input, 0x20), 32) // baseLen
            mstore(add(input, 0x40), 32) // expLen
            mstore(add(input, 0x60), 32) // modLen
            mstore(add(input, 0x80), 2) // base = 2
            mstore(add(input, 0xA0), 256) // exp  = 256
            mstore(add(input, 0xC0), m) // mod  = m

            let ok := staticcall(gas(), 0x05, add(input, 0x20), 0xC0, add(input, 0x20), 0x20)
            if iszero(ok) {
                mstore(0x00, 0xf6f1d8c5) // ModExpFailed() selector
                revert(0x1c, 0x04)
            }
            out := mload(add(input, 0x20))
        }
    }

    /// @dev Exact division: computes ((hi*2^256 + lo - rem) / d), where rem = (hi*2^256 + lo) mod d.
    ///      Requires hi < d.
    ///      Uses a standard full-precision exact-division technique.
    function _exactDiv512By256(uint256 hi, uint256 lo, uint256 d, uint256 rem) private pure returns (uint256 q) {
        unchecked {
            // Subtract remainder from [hi lo]
            if (rem > lo) {
                hi -= 1;
                lo -= rem;
            } else {
                lo -= rem;
            }

            // Factor powers of two out of d
            uint256 twos = d & (~d + 1);
            d /= twos;

            // Divide [hi lo] by twos
            lo /= twos;

            // twos = 2^256 / twos
            assembly {
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Merge hi into lo
            lo |= hi * twos;

            // Inverse of d mod 2^256 (Newton-Raphson)
            uint256 inv = (3 * d) ^ 2;
            inv *= 2 - d * inv; // 2^8
            inv *= 2 - d * inv; // 2^16
            inv *= 2 - d * inv; // 2^32
            inv *= 2 - d * inv; // 2^64
            inv *= 2 - d * inv; // 2^128
            inv *= 2 - d * inv; // 2^256

            q = lo * inv;
        }
    }

    /*//////////////////////////////////////////////////////////////
                           DIVISION: 512 / 512 -> uint256
    //////////////////////////////////////////////////////////////*/

    /// @notice Divide a 512-bit unsigned integer by a 512-bit unsigned integer.
    /// @dev Returns a uint256 quotient (checked). Reverts if quotient would not fit uint256.
    ///      - If b.hi != 0, the quotient is guaranteed to fit uint256.
    ///      - If b.hi == 0, the quotient may exceed uint256; in that case we revert.
    /// @return q256 The quotient as uint256.
    /// @return r The remainder as U512.
    function div(U512 memory a, U512 memory b) internal view returns (uint256 q256, U512 memory r) {
        if (b.hi == 0 && b.lo == 0) revert DivByZero();

        // Denominator fits in uint256 => use 512/256 division then require quotient fits uint256.
        if (b.hi == 0) {
            (U512 memory q512, uint256 rem) = div(a, b.lo);
            if (q512.hi != 0) revert DivQuotientTooLarge();
            q256 = q512.lo;
            r = U512(rem, 0);
            return (q256, r);
        }

        // If a < b then quotient = 0, remainder = a
        if (lt(a, b)) {
            return (0, a);
        }

        unchecked {
            // Estimate an upper bound for q, then binary-search downward until b*q <= a.
            uint256 low = 0;
            uint256 high = a.hi / b.hi;
            U512 memory prod;

            while (low < high) {
                uint256 mid = high - ((high - low) / 2);
                (bool ok, U512 memory candidate) = _tryMul(b, mid);
                if (ok && !gt(candidate, a)) {
                    low = mid;
                    prod = candidate;
                } else {
                    high = mid - 1;
                }
            }

            q256 = low;
            if (q256 != 0) {
                (, prod) = _tryMul(b, q256);
            }
            r = sub(a, prod);
        }
    }

    /*//////////////////////////////////////////////////////////////
                        DIVISION: uint256 / 512 -> uint256
    //////////////////////////////////////////////////////////////*/

    /// @notice Divide a uint256 by a 512-bit unsigned integer.
    /// @dev The quotient always fits in uint256. If b.hi != 0 then b >= 2^256 and quotient is 0.
    /// @return q256 The quotient as uint256.
    /// @return r256 The remainder as uint256 (equals a when q256==0).
    function div(uint256 a, U512 memory b) internal pure returns (uint256 q256, uint256 r256) {
        if (b.hi == 0 && b.lo == 0) revert DivByZero();
        if (b.hi != 0) {
            return (0, a);
        }
        return (a / b.lo, a % b.lo);
    }

    /*//////////////////////////////////////////////////////////////
                             HELPERS
    //////////////////////////////////////////////////////////////*/

    /// @notice Canonical predicate for deciding whether a U512 high limb has entered the expansion-warning zone.
    /// @dev This is a warning-only condition. Crossing this threshold must not revert by itself.
    function needsExpansion(uint256 hi) internal pure returns (bool) {
        return hi >= HI_WARNING_THRESHOLD;
    }

    /// @notice Safe cast to uint256 (reverts if a doesn't fit).
    function toUint256(U512 memory a) internal pure returns (uint256) {
        if (a.hi != 0) revert DivQuotientTooLarge();
        return a.lo;
    }
}
