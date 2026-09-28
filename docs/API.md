# API Contract

`U512Math` is an internal Solidity library. Its functions are compiled into the
consumer; the library is not normally deployed or called as an independent
contract.

## Type

```solidity
struct U512 {
    uint256 lo;
    uint256 hi;
}
```

The declaration and ABI tuple order is `lo`, then `hi`.

The represented value is:

```text
hi × 2^256 + lo
```

## Constant

```solidity
uint256 constant HI_WARNING_THRESHOLD =
    0x7000000000000000000000000000000000000000000000000000000000000000;
```

The constant is advisory. Crossing it does not itself cause a revert.

## Comparison

```solidity
eq(U512 a, U512 b)  -> bool
lt(U512 a, U512 b)  -> bool
gt(U512 a, U512 b)  -> bool
gte(U512 a, U512 b) -> bool
```

All comparison functions are `internal pure`.

## Arithmetic

```solidity
add(U512 a, U512 b)        -> U512
sub(U512 a, U512 b)        -> U512
mul256(uint256 a, uint256 b) -> U512
mul(U512 a, uint256 b)     -> U512
mul(U512 a, U512 b)        -> U512
```

These functions are `internal pure`. Addition, subtraction, and both checked
`mul` overloads revert instead of accepting results outside the unsigned
512-bit range. `mul256` always returns the complete product of two `uint256`
values.

## Division

```solidity
div(U512 a, uint256 d)       -> (U512 q, uint256 r)
divToUint256(U512 a, uint256 d) -> (uint256 q, uint256 r)
div(U512 a, U512 b)          -> (uint256 q, U512 r)
div(uint256 a, U512 b)       -> (uint256 q, uint256 r)
```

The first three are `internal view`; division of `uint256` by `U512` is
`internal pure`.

Every successful division satisfies the corresponding quotient/remainder
identity and remainder bound. Zero denominators revert.

## Helpers

```solidity
needsExpansion(uint256 hi) -> bool
toUint256(U512 a)          -> uint256
```

Both helpers are `internal pure`. `toUint256` reverts if `a.hi != 0`.

## Errors

| Error | Selector | Meaning |
|---|---|---|
| `U512_Underflow()` | `0x67ab763d` | Unsigned subtraction would be negative |
| `U512_Overflow()` | `0x75aace1d` | Exact result would exceed 512 bits |
| `DivByZero()` | `0x2eb48d5e` | Denominator is zero |
| `DivQuotientTooLarge()` | `0xd6e222f7` | Required `uint256` result does not fit |
| `ModExpFailed()` | `0x1f7ec5f0` | EVM precompile call failed |

## Warning event

```solidity
event U512ExpansionWarning(
    bytes32 indexed tag,
    uint256 hi,
    uint256 threshold
);
```

Topic:

```text
0xe1b83638431429bb34e676279d23f50b074a93fa0c9da8938d54867c55756157
```

The library declares the canonical event but does not emit it. A consumer may
emit it after detecting `needsExpansion(value.hi)`.
