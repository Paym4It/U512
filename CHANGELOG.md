# Changelog

All notable changes to U512 will be documented in this file.

The project follows Semantic Versioning.

## [0.1.0] - 2026-09-28

### Added

- Reproducible Foundry 1.5.1 and Solidity 0.8.33 configuration.
- Exact migration provenance for the original implementation.
- API, mathematical model, provenance, and consumer documentation.
- Fifty deterministic unit tests.
- Ten fuzz properties.
- Three stateful invariants.
- Seven independently derived reference vectors.
- Eight deployable-harness integration tests.
- `U512Harness` demonstration contract.
- Foundry deployment script for the demonstration harness.
- CI enforcement of the 78-test census.

### Changed

- Relocated the production library to `src/U512Math.sol`.
- Applied `AGPL-3.0-or-later` notices to owned Solidity sources.
- Separated inherited fuzz properties from deterministic unit tests.
- Removed protocol-specific wording from production NatSpec.

### Security

- Preserved checked overflow, underflow, division, and conversion behavior.
- Preserved the warning threshold, error selectors, and event topic.
- Added boundary, vector, invariant, and precompile integration coverage.
