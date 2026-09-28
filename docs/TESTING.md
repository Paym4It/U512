# Testing

The validation suite contains 78 tests.

## Distribution

- Unit tests: 50
- Fuzz properties: 10
- Stateful invariants: 3
- Reference vectors: 7
- Harness integration tests: 8

The original 27 tests remain present: 25 deterministic tests and two inherited
fuzz properties.

## Independent vectors

Reference vectors are derived from integer identities rather than from
U512Math itself. They include:

- Maximum `uint256` squared.
- Carry and borrow across limb boundaries.
- Division of `2^256` by three.
- Division of `2^512 - 1` by `2^256 - 1`.
- Division of `2^512 - 1` by `2^256`.

## Local validation

    mise exec -- forge fmt --check
    mise exec -- forge build --no-cache
    mise exec -- forge test

## Harness deployment

For an unlocked local Anvil account:

    mise exec -- forge script \
      script/DeployU512Harness.s.sol:DeployU512Harness \
      --rpc-url http://127.0.0.1:8545 \
      --sender <unlocked-address> \
      --broadcast \
      --unlocked

The harness is demonstration and verification infrastructure. It is not a
required production deployment.

RSK precompile behavior is validated independently through the external consumer suite.
