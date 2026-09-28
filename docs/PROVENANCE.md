# Provenance

U512 is an original HIRME software product owned by Hirme Labs LLC.

## Original development baseline

The implementation was originally developed within:

```text
Repository: https://github.com/Paym4It/hirme-fee-sharing
Branch: main
Commit: 4598ed1e22a63106d7e9d798b08252469b9edf0d
Tree: ff2b64c01f2d086f4dbf83b3d21e61ce2680815f
```

## Original files

```text
src/shared/u512/U512Math.sol
SHA-256: c71d12fa6c7824fee1cf8d38d72012765b306d6f1a38bf5d24cc5212defe8228
Git blob: 389e66c173debdbdb94cbd02466b62452a9f974e

test/core/U512Math.t.sol
SHA-256: f5d9b05fc500cd61d5a3cf5bb7feb25549ce262fac0af3b1fc091f0baf7e8771
Git blob: 4abce543726ca2f8b0e6e90b26284959ea5ca79d

test/u512/U512MathExtended.t.sol
SHA-256: 172c7f6fbf6ee910e700b6a3ff4855f3236e0aafcafa335c3212517f37d6c9f9
Git blob: 223ef11126a3b9a332320de5a1d0c5675a3c9483
```

## Laboratory migration

The exact byte-for-byte import is recorded by:

```text
Commit: 5b1ac1d79f9ab4b22ae4cae1a014a690a3608a47
Tree: db1afc91a699151afbd0cd8c69dc8faf02c4abdf
```

The relocation-only adaptation is recorded by:

```text
Commit: 218ad48877f5f911e345bb941619f0d27c538dd2
Tree: c8d1d1319e4c60bda66c4bfb2e3c56e6b91904b7
```

That adaptation changed only the two test import paths. Production mathematics
remained byte-for-byte identical.

## Licensing transition

The imported files retained their historical MIT markers in the exact
migration checkpoint. Hirme Labs LLC subsequently selected
`AGPL-3.0-or-later` for the independent U512 product and updated the owned
source and test notices without changing executable semantics.

General full-precision arithmetic techniques and use of a standard EVM
precompile do not imply third-party source-code provenance. No third-party
Solidity source is included in `src/`.

`forge-std` is a development-only dependency and is documented separately in
`THIRD_PARTY_NOTICES.md`.

## Accepted independent candidate

The independently validated candidate used for the first public export is
identified by:

```text
Candidate commit: 217dcda98c9c6514e3361d585a590bd04b964bd6
Candidate tree:   95f8734bd2c45b34d85cacd1109719cb966ec0ef
U512Math SHA-256: f4cf85daaa82f56c27afe86b3960f7cdfca9b1ff5fec37063760dd9d9f4521c5
```

The public repository was created with a new Git history through an explicit
allowlist export. Production source, tests, examples, and deployment tooling
were preserved byte for byte. Only public-facing documentation and repository
metadata were adapted.
