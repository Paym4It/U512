# Changes from FEE-SHARE

## Phase 4: relocation

The production library moved from:

```text
src/shared/u512/U512Math.sol
```

to:

```text
src/U512Math.sol
```

The direct tests moved to:

```text
test/unit/U512Math.t.sol
test/unit/U512MathExtended.t.sol
```

Their relative import changed from:

```solidity
import {U512Math} from "../../src/shared/u512/U512Math.sol";
```

to:

```solidity
import {U512Math} from "../../src/U512Math.sol";
```

No production logic changed.

## Phase 5: independent package identity

The owned Solidity files changed from the historical MIT marker to:

```solidity
// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (C) 2026 Hirme Labs LLC
```

Protocol-specific examples were removed from production NatSpec. The phrase
describing an algorithm as “adapted from full-precision mulDiv” was replaced
with a neutral description of the standard mathematical technique.

Documentation was rewritten around the independent library API, mathematical
model, dependency boundary, provenance, and consumer integration.

## Explicitly unchanged

Phase 5 did not change:

- Struct field order.
- Constants.
- Function signatures or mutability.
- Arithmetic expressions or control flow.
- Errors or selectors.
- Event signature or topic.
- Precompile address.
- Test behavior.

Semantic hashes and the inherited 27-test suite are used to enforce this
boundary.
