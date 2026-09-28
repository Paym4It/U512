# Architecture

## Production component

U512 exposes one production file:

    src/U512Math.sol

It has no Solidity imports. It relies only on native EVM arithmetic and the
modular-exponentiation precompile at address `0x05`.

All callable library functions are internal and are incorporated into the
consumer during compilation. The library is not a normal deployment target.

## Development components

    examples/U512Harness.sol
    script/DeployU512Harness.s.sol

The harness exposes external wrappers for testing and demonstrations. It is not
required by consumers and is not protocol infrastructure.

## Test organization

    test/unit/        Deterministic behavior and boundaries
    test/fuzz/        Property-based arithmetic checks
    test/invariant/   Stateful accumulator invariants
    test/integration/ Harness and precompile integration
    test/vectors/     Independently derived mathematical vectors

## Dependency boundary

Production:

    U512Math -> native EVM operations and precompile 0x05

Development:

    tests, harness deployment script -> forge-std 1.14.0

No protocol storage, token, proxy, governance, access-control, mutex, or
multisig behavior belongs to this package.
