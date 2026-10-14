# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

A Wolfram Language implementation that computes the complete hyperbolic structure, holonomy, Dirichlet domain, and volume of a cusped hyperbolic 3-manifold from an ideal triangulation (isomorphism signature). The main target is the knot complement K14n12345 (20 tetrahedra); K5a1 and the figure-eight knot (`cPcbbbiht`) serve as regressions. The geometry is deliberately **independent of SnapPy/Regina/Python**: SnapPy appears only in the separate comparison harness and must never feed data into the Wolfram solver beyond the original dataset records.

## Commands

Wolfram 15.0.1. Scripts locate the repo root via `$InputFileName` (everything in `tests/` uses the parent of its own directory), so they **must be run with an absolute script path**. Layout: `src/` holds the package, `tests/` holds the test suite and validation scripts, there are no top-level drivers; `tests/RunTests.wl` is the entry point.

```sh
K=/Applications/Wolfram.app/Contents/MacOS/WolframKernel
$K -script "$PWD/tests/RunTests.wl"                       # all suites in dependency order, writes outputs/tests.json, exit 1 on failure
$K -script "$PWD/tests/RunTests.wl" Hyperbolic3Manifolds  # run only the named suite(s)
$K -script "$PWD/tests/CheckPrecision.wl"  # re-solve at 160 digits, compare to outputs/structure.wxf
$K -script "$PWD/tests/TestK5a1.wl"        # end-to-end regression on K5a1 -> outputs/K5a1/
```

Suites (`tests/*.wlt`, run by `RunTests.wl` in this order):

- `ImportDataset` — re-extracts the K14n12345 row from the pinned CSV and checks it equals `data/14n12345-record.json` and the provenance SHA-256. Skipped when `data/knots_and_links_through_14.csv` is absent.
- `Run14n12345` — full pipeline; writes `outputs/face-pairings.json` and `outputs/{structure,holonomy,domain,domain-integral}.wxf`.
- `RefineIntegral` — re-integrates the saved domain and compares with the saved integral.
- `MakeReport` — writes `outputs/results.json`, `outputs/14n12345-Wolfram.nb`, `outputs/domain-preview.png`.
- `Hyperbolic3Manifolds` — unit/regression checks on the saved artifacts plus the figure-eight volume.

The later suites read files the `Run14n12345` suite writes, so run it first (`RunTests.wl` does). Inside a `.wlt`, never `Exit`; guard each stage with `If[AssociationQ[prev], ..., $Failed]` so a failure is reported as failed tests instead of killing `TestReport`.

A project hook (`.claude/hooks/require-tests.sh`, registered in `.claude/settings.json`) enforces this: after any edit under `src/`, Claude cannot finish until a full `tests/RunTests.wl` run newer than the edit has passed (it checks `outputs/tests.json`).

Each `.wlt` is a plain sequence of setup lines and `VerificationTest[...]` with `TestID`s; to run one test, evaluate the setup lines at the top of its file plus the single `VerificationTest` in a kernel.

SnapPy comparison (uses the local `.venv`, Python 3.12, pinned in `tests/requirements-snappy.txt`):

```sh
.venv/bin/python tests/CompareSnapPy.py prepare          # needs data/knots_and_links_through_14.csv
$K -script "$PWD/tests/CompareSnapPy.wl"
.venv/bin/python tests/CompareSnapPy.py report          # -> outputs/snappy-comparison/comparison.{md,csv,json}
```

## Architecture

`src/Hyperbolic3Manifolds.wl` is the single package (`Hyperbolic3Manifolds`` context); every test file `Get`s it via `FileNameJoin[{root,"src","Hyperbolic3Manifolds.wl"}]`. The public functions form a linear pipeline, each taking and returning an `Association` (or a `Failure`, via `Catch`/`Throw`; test suites check `AssociationQ` before each stage):

1. `DecodeTriangulation[sig]` — classic connected isomorphism signature -> face pairings (`"FacePairings"` with `neighbor`, `vertex_permutation`, 0-based). Peripheral (meridian/longitude) decoration is not decoded.
2. `ValidateIdealTriangulation[t]` — vertex-link Euler characteristics, cusp count, reversed edges.
3. `AngleSystem[t]` — exact integer angle constraint matrix and its nullspace.
4. `SolveCompleteStructure[t, wp, goal]` — Newton maximization of the Lobachevsky volume functional restricted to the angle-space nullspace (Casson–Rivin). Returns angles, shapes, volume, and residuals (`AngleEquationResidual`, `GradientResidual`, `ComplexEdgeResidual`, `BlochWignerVolume`, `QuadratureVolume`). Standard settings are `wp=120, goal=45`; the precision check uses `160, 65`.
5. `BuildHolonomy[t, s]` — develops tetrahedra through Möbius maps; face-pairing generators in PSL(2,C). Basepoint `(1/2,1/3,1)` in upper half space.
6. `BuildDirichletDomain[h]` — Klein-model bisector halfspaces, polar convex hull, iteratively adding products of active generators until stable; returns vertices/edges/faces, `FacePairs`, and pairing/edge-cycle residuals. **Machine precision.**
7. `IntegrateDomainVolume[d, goal]` — independent volume via divergence theorem on domain faces.
8. `DomainGraphics[d, "Poincare"|"Klein"]`.

Artifacts are persisted between stages as WXF in `outputs/` (`structure`, `holonomy`, `domain`, `domain-integral`), so later suites and scripts (`MakeReport`, `RefineIntegral`, `CheckPrecision`, `Hyperbolic3Manifolds`) reload rather than recompute.

## Conventions and constraints

- Numerical thresholds used across tests/drivers: structure residuals `< 10^-40` (gradient `< 10^-45`); domain residuals `< 10^-9`; domain integral vs tetrahedral volume `< 10^-7`; SnapPy comparison tolerance `1e-30`. The dataset's rounded volume is for comparison only, never an input.
- Scope is intentionally limited (see README "Scope and limitations"): orientable, face-paired ideal triangulations with torus cusps and a strictly positive angle structure. Unsupported input should fail explicitly, not be silently accepted. Results are numerical evidence, not interval-certified; don't describe them as proofs.
- `tests/ImportDataset.wlt` uses a deliberately narrow parser for the one unquoted CSV row; it rejects quoted records rather than parsing general CSV.
- Data provenance is pinned in `data/provenance.json` (dataset commit `f3eb9cdd…`, CSV SHA-256). `data/knots_and_links_through_14.csv` (32 MB), `outputs/*.log`, and `.venv/` are gitignored and regenerable.
