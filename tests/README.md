# tests

Test suites, regression scripts and the SnapPy comparison harness. Wolfram 15.0.1 was used.

Every script finds the repository root from its own location (`$InputFileName`), so it **must be run with an absolute path**. The commands below assume you are in the repository root.

```sh
K=/Applications/Wolfram.app/Contents/MacOS/WolframKernel
```

## Test suites

```sh
$K -script "$PWD/tests/RunTests.wl"                                   # all suites
$K -script "$PWD/tests/RunTests.wl" Run14n12345 MakeReport            # only the named suites
```

`RunTests.wl` runs the suites in dependency order, writes a summary to `outputs/tests.json`, and exits with status 1 if any test fails.

| Suite | What it does |
|---|---|
| `ImportDataset.wlt` | Re-extracts the K14n12345 row from the pinned CSV, checks the CSV's SHA-256 against `data/provenance.json`, and checks the row equals `data/14n12345-record.json`. `RunTests.wl` skips it when `data/knots_and_links_through_14.csv` is absent; run on its own, the suite downloads the CSV from the pinned commit. |
| `Run14n12345.wlt` | Full pipeline on K14n12345. Writes `outputs/face-pairings.json` and `outputs/{structure,holonomy,domain,domain-integral}.wxf`. |
| `RefineIntegral.wlt` | Re-integrates the saved domain and compares with the saved integral. |
| `MakeReport.wlt` | Writes `outputs/results.json`, `outputs/14n12345-Wolfram.nb` and `outputs/domain-preview.png`. |
| `Hyperbolic3Manifolds.wlt` | Unit and regression checks on the saved artifacts, plus the figure-eight volume. |

The later suites read the files `Run14n12345.wlt` writes, so run it first (`RunTests.wl` does). In a notebook, evaluate `TestReport["/absolute/path/to/tests/Run14n12345.wlt"]`. PNG export needs a working Wolfram graphics renderer; the numerical computation does not need a notebook front end.

Thresholds used throughout: structure residuals `< 10^-40` (gradient `< 10^-45`), domain residuals `< 10^-9`, domain integral vs. tetrahedral volume `< 10^-7`.

## Precision check

```sh
$K -script "$PWD/tests/CheckPrecision.wl"
```

Re-solves K14n12345 at 160-digit working precision (goal 65) and compares with the 120-digit result saved in `outputs/structure.wxf`.

## K5a1 regression

```sh
$K -script "$PWD/tests/TestK5a1.wl"
```

Runs the whole pipeline on the three-tetrahedron K5a1 complement (signature `dLQcbcciirv_BacB`) with the unchanged package and writes results and a notebook to `outputs/K5a1/`. Its 12 checks cover the angle structure, gluing and stationarity residuals, a 160-digit re-solve, face pairing and edge-cycle residuals, and the independent domain integral.

- Volume: `2.82812208833078316276389880927663494277...`
- Domain: 45 vertices, 69 edges, 26 faces
- Domain integral minus tetrahedral volume: about `1.17e-11`

## Two-cusped census manifolds

```sh
$K -script "$PWD/tests/TestCensus.wl"
```

Runs the whole pipeline on the two-cusped census manifolds m412 (`fLLQcbdeedemnamjp`, 5 tetrahedra) and m203 (`eLMkbcddddedde`, 4 tetrahedra) and writes `record.json`, `results.json` and the README image `preview.png` to `outputs/m412/` and `outputs/m203/`. The signatures come from SnapPy 3.3.2 (`triangulation_isosig(decorated=False)`); SnapPy's 10-digit volumes are used only for the comparison check.

The signatures were cross-checked once, by hand, with the C++ engine of Regina 7.4.1, built from the release tarball. This check is not part of the test suite and Regina is not a dependency. For each signature:

- `regina::Census::lookup` finds it in Regina's orientable cusped hyperbolic census under the expected name (`m412 : #1`, `m203 : #1`). m203 is also listed as `L206002` in Christy's knot/link table.
- Regina builds the manifold from its own copy of the Callahan–Hildebrand–Weeks census data (`SnapPeaCensusManifold(SEC_5, n).construct()`). The result has the identical isomorphism signature, and `isIsomorphicTo` confirms it matches the decoded triangulation.

The names m412 and m203 come from the Callahan–Hildebrand–Weeks census in both programs, so the cross-check confirms that the triangulations exist and carry those names in two independent codebases. It does not independently re-derive the naming. Each manifold gets 12 checks: tetrahedron and torus-cusp counts, the structure residuals, agreement with the reference volume to `1e-9`, two ideal vertices, face pairing and edge-cycle residuals, and the independent domain integral. Exits 1 if any check fails.

| Manifold | Volume | Domain V, E, F | Integral minus volume |
|---|---|---|---|
| m412 | `5.07470803204826812510...` | 56, 86, 32 | about `2.5e-11` |
| m203 | `4.05976642563861450008...` | 48, 74, 28 | about `2.0e-11` |

## SnapPy comparison

A separate harness compares Wolfram volumes with freshly computed SnapPy volumes. SnapPy is used only here: nothing it computes is passed to the Wolfram solver, which receives only the original dataset records.

Setup: a local `.venv` with Python 3.12 and SnapPy 3.3.2; exact versions are pinned in `requirements-snappy.txt`. The CSV must be in `data/` (see [`data/README.md`](../data/README.md)).

```sh
.venv/bin/python tests/CompareSnapPy.py prepare
$K -script "$PWD/tests/CompareSnapPy.wl"
.venv/bin/python tests/CompareSnapPy.py report
```

The ten samples are K4a1, K5a1, K6a1, K7a1, K8a1, K9a1, K10a1, K11n1, K12n1 and K14n12345 (2–20 tetrahedra). Each is compared using SnapPy's `Manifold.high_precision().volume()`, computed from both the dataset signature and the knot name, against a 120-digit Wolfram solve. The absolute tolerance is `1e-30`. All ten pass, together with the Wolfram positivity, angle, complex gluing, stationarity and volume-formula checks. The comparison covers volumes only; it does not build Dirichlet domains.

Results are written to `outputs/snappy-comparison/comparison.{md,csv,json}`, alongside the raw engine output and the exact sample records.
