# Mathematical Model

## Representation

A U512 value contains two unsigned 256-bit limbs:

```text
value = hi × 2^256 + lo
```

Each limb satisfies:

```text
0 <= limb < 2^256
```

Therefore:

```text
0 <= value < 2^512
```

The Solidity declaration order is `lo`, then `hi`, even though mathematical
notation conventionally writes the high limb first.

## Checked arithmetic

Addition propagates low-limb carry into the high limb. It reverts if the exact
result would reach or exceed `2^512`.

Subtraction borrows from the high limb when necessary. It reverts whenever the
mathematical result would be negative.

Multiplication succeeds only when the full exact result fits inside 512 bits.
`mul256` is the exception in form, not safety: every product of two 256-bit
values fits exactly in 512 bits.

## Division

Every successful division satisfies:

```text
dividend = quotient × divisor + remainder
```

and:

```text
0 <= remainder < divisor
```

The library rejects a zero divisor. Operations that promise a `uint256`
quotient also reject quotients that exceed that range.

The 512-by-256 algorithm computes `2^256 mod divisor` through the standard EVM
modular-exponentiation precompile at address `0x05`. After removing the exact
remainder, it completes exact division using the modular inverse of the odd
part of the divisor.

## Warning threshold

The frozen threshold is:

```text
0x7000000000000000000000000000000000000000000000000000000000000000
```

Exactly:

```text
HI_WARNING_THRESHOLD = 7 × 16^63 = 7 × 2^252
```

It is not equal to `2^254`.

The predicate is:

```text
needsExpansion(hi) = (hi >= HI_WARNING_THRESHOLD)
```

This is an advisory engineering signal. It does not reduce the valid U512
range and does not make an otherwise valid operation revert.

## Safe conversion

A U512 value can be converted to `uint256` exactly when:

```text
hi == 0
```

A nonzero high limb causes the conversion to revert rather than truncate.
