# Consumer Integration

Install U512 as a pinned Solidity dependency from its public repository.

## Soldeer configuration

```toml
[dependencies]
u512 = {
    version = "0.1.0",
    git = "https://github.com/Paym4It/U512.git",
    tag = "v0.1.0"
}
```

## Remapping

```text
u512/=dependencies/u512-0.1.0/
```

## Import

```solidity
import {U512Math} from "u512/src/U512Math.sol";
```

## Basic use

```solidity
pragma solidity ^0.8.33;

import {U512Math} from "u512/src/U512Math.sol";

contract Accumulator {
    using U512Math for U512Math.U512;

    U512Math.U512 internal total;

    function add(uint256 amount) external {
        total = total.add(
            U512Math.U512({
                lo: amount,
                hi: 0
            })
        );
    }

    function value()
        external
        view
        returns (uint256 lo, uint256 hi)
    {
        return (total.lo, total.hi);
    }
}
```

A consumer that wants operational warning events must check
`needsExpansion(value.hi)` and emit `U512ExpansionWarning` itself.

## Deployment model

The library normally has no independent deployment address. Its internal
functions are incorporated into the consuming contract.

The deployable demonstration wrapper is provided in
`examples/U512Harness.sol`; its Foundry deployment script is
`script/DeployU512Harness.s.sol`.

## Version pinning

Production consumers should pin an immutable release tag and retain the
resulting `soldeer.lock`. Depending directly on `main` is not recommended.

## Licensing

U512 is provided under `AGPL-3.0-or-later`. Consumers are responsible for
evaluating and satisfying the license obligations that apply to their combined
and distributed software. This document is technical guidance, not legal
advice.
