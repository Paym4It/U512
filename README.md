# U512

U512 is a Solidity library for checked unsigned 512-bit arithmetic using two
256-bit limbs.

This is the public, reusable U512 package maintained by Hirme Labs LLC.

## Features

- Exact unsigned representation from zero through `2^512 - 1`.
- Checked addition and subtraction.
- Full `uint256 × uint256` multiplication.
- Checked `U512 × uint256` and `U512 × U512` multiplication.
- Division across supported 256-bit and 512-bit representations.
- Checked conversion back to `uint256`.
- Advisory high-range detection.
- EVM modular-exponentiation precompile support.

## Representation

```text
value = hi × 2^256 + lo
```

The Solidity struct declaration order is stable:

```solidity
U512Math.U512({lo: lowLimb, hi: highLimb})
```

## Installation

Pin an immutable release in `soldeer.toml`:

```toml
[dependencies]
u512 = {
    version = "0.1.0",
    git = "https://github.com/Paym4It/U512.git",
    tag = "v0.1.0"
}
```

Use the corresponding remapping:

```text
u512/=dependencies/u512-0.1.0/
```

Install it with:

```bash
forge soldeer install --config-location soldeer --clean
```

## Import

```solidity
import {U512Math} from "u512/src/U512Math.sol";
```

See `docs/CONSUMER_INTEGRATION.md` for a complete integration example.

## Development setup

```bash
mise trust
mise install
mise exec -- forge soldeer install --config-location soldeer --clean
mise exec -- forge build
mise exec -- forge test
```

The validation suite contains 78 tests across unit, fuzz, invariant,
reference-vector, and integration categories. See `docs/TESTING.md`.

## Production dependencies

`src/U512Math.sol` has no Solidity imports and no third-party production
dependency. `forge-std` is used only by development tooling and tests.

## Non-goals

U512 does not provide:

- Signed arithmetic.
- Fixed-point arithmetic.
- Arbitrary precision beyond 512 bits.
- Protocol storage, governance, proxies, access control, or token logic.
- A claim of professional security audit.

## Releases

The first stable release is `v0.1.0`. Immutable release tags should be used by
consumers instead of branches.

## License

U512 is licensed under `AGPL-3.0-or-later`.

Copyright (C) 2026 Hirme Labs LLC.
