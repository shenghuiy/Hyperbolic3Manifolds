# Hyperbolic 3-manifolds in Wolfram Language

A reproducible continuation of the [shared discussion](https://chatgpt.com/s/cx_6acfd5ee2c588191a692c39b136afa23), starting with the public triangulation for **K14n12345**. The geometry, linear algebra, numerical integration, and graphics are implemented in Wolfram Language. No SnapPy, SnapPea, Regina, Python, or external geometry engine is called by the computation.

## Open the result

Open `outputs/14n12345-Wolfram.nb` in Wolfram Desktop. It contains rotatable Poincare and Klein views of the computed polyhedron. `outputs/results.json` contains numerical diagnostics, and the WXF files preserve the shapes, holonomy matrices, domain, and quadrature results.

Computed tetrahedral volume:

```
18.36536110161047534340644954313593224436235757255441338977
```

The domain has **161 vertices, 243 edges, 84 faces**, and one ideal vertex. The independent domain integral is approximately `18.3653611015266`, differing from the tetrahedral sum by about `8.4e-11`. The domain geometry is machine precision; printing extra quadrature digits does not increase its accuracy. The dataset's rounded volume is used only for comparison.

## Run

Wolfram 15.0.1 was used. From a terminal, use an absolute script path:

```sh
/Applications/Wolfram.app/Contents/MacOS/WolframKernel -script /absolute/path/Hyperbolic3Manifolds/Run14n12345.wl
/Applications/Wolfram.app/Contents/MacOS/WolframKernel -script /absolute/path/Hyperbolic3Manifolds/tests/RunTests.wl
/Applications/Wolfram.app/Contents/MacOS/WolframKernel -script /absolute/path/Hyperbolic3Manifolds/tests/CheckPrecision.wl
```

Alternatively, evaluate `Get["/absolute/path/Hyperbolic3Manifolds/Run14n12345.wl"]` in a notebook. The supplied small JSON record is sufficient to run the geometry offline. `tests/ImportDataset.wl` extracts it again from the pinned CSV, downloading the CSV if absent. The importer uses a checked parser for this unquoted row, not a general CSV parser. PNG export needs a functioning Wolfram graphics renderer; numerical computation does not require a notebook front end.

## Dataset

The full knot database (`knots_and_links_through_14.csv`, 32 MB) is **not stored in this repository**. It comes from the [`3-manifolds/snappy_15_knots`](https://github.com/3-manifolds/snappy_15_knots) repository, pinned to commit `f3eb9cdd16e1792dd84476a945315049873e8ac1`:

- [View the CSV on GitHub](https://github.com/3-manifolds/snappy_15_knots/blob/f3eb9cdd16e1792dd84476a945315049873e8ac1/manifold_src/original_manifold_sources/knots_and_links_through_14.csv)
- [Direct download (raw)](https://raw.githubusercontent.com/3-manifolds/snappy_15_knots/f3eb9cdd16e1792dd84476a945315049873e8ac1/manifold_src/original_manifold_sources/knots_and_links_through_14.csv)

SHA-256: `a210bc6866a22c8d3aa533a0804d650ffb68659f83ac5dcdb3ef3e57bef59464` (also recorded in `data/provenance.json`).

The main computation does not need it: the K14n12345 record is already saved in `data/14n12345-record.json`. You need the CSV only to re-extract that record (`tests/ImportDataset.wl` downloads it automatically) or to run the SnapPy comparison (`tests/CompareSnapPy.py prepare`). To fetch it manually:

```sh
curl -L -o data/knots_and_links_through_14.csv https://raw.githubusercontent.com/3-manifolds/snappy_15_knots/f3eb9cdd16e1792dd84476a945315049873e8ac1/manifold_src/original_manifold_sources/knots_and_links_through_14.csv
shasum -a 256 data/knots_and_links_through_14.csv
```

## Mathematical pipeline

1. **Decode the isomorphism signature.** Read base-64 integers, facet actions, destination tetrahedra, and vertex permutations. Reconstruct reciprocal face identifications and orient the tetrahedra. Peripheral decoration is retained but not decoded; no meridian/longitude calculation is claimed.
2. **Check ideal topology.** Build vertex-link triangles and their edge/vertex equivalence classes. Check for reversed tetrahedron edges and require each oriented link to have Euler characteristic zero. Here the result is one torus cusp.
3. **Construct angle space.** Each tetrahedron contributes three opposite-edge angles summing to pi; angles around each quotient edge sum to 2 pi. The exact integer constraint matrix has rank 39 on 60 angles, giving 21 deformation directions. Linear optimization finds a strictly positive starting point.
4. **Solve the complete structure.** Maximize the sum of Lobachevsky functions with Newton steps restricted to the exact constraint nullspace. An interior stationary point on angle space gives a complete structure under the Casson–Rivin theorem. Numerical residuals are evidence for that point, not an interval existence proof. This is why solving only the edge products would be insufficient.
5. **Recover shapes and holonomy.** Convert angles to complex shapes and account for tetrahedron orientation. Develop adjacent tetrahedra through Mobius maps determined by three ideal vertices. Tree development leaves face-pairing generators in PSL(2,C). The chosen basepoint is `(1/2,1/3,1)` in upper half space and becomes the ball center.
6. **Construct a candidate Dirichlet domain.** For the hyperboloid image `(q0,q)` of the basepoint under an isometry, its Klein bisector halfspace is `q.k <= q0-1`. Use a polar convex hull, adding cuts from products of current active generators until stable. Check reciprocal face identifications, vertex images, polyhedron Euler characteristic, and edge-cycle angles.
7. **Integrate independently.** Klein hyperbolic density is `(1-|k|^2)^(-2)`. A radial vector field `F(k)=f(r) k`, with

   ```
   f(r) = (r/(1-r^2) - arctanh(r)) / (2 r^3),
   ```

   has divergence equal to that density. The divergence theorem reduces volume to numerical integration on triangles covering the polyhedron faces. The ideal-vertex singularities are integrable. This calculation uses the domain coordinates, not the tetrahedral volume sum.
8. **Visualize.** Klein edges are straight. The map `p=k/(1+sqrt(1-|k|^2))` produces the Poincare ball view, where geodesic edges and faces are curved.

## Scope and limitations

- This is a numerical implementation for connected, orientable, face-paired ideal triangulations with torus links and an interior volume maximum. It is **not an algorithm for every 3-manifold**. Boundary faces, nonorientable input, and triangulations with no strictly positive angle structure are rejected. A failure of this solver does not prove nonhyperbolicity.
- The signature decoder targets classic connected signatures; it does not support arbitrary newer signature variants or arbitrary cusp decorations.
- A stabilized finite search over bisector cuts is not by itself a proof that all group elements have been considered. The face/edge diagnostics and independent volume agreement provide strong numerical checks, but do not constitute a full certified Poincare polyhedron theorem verification.
- There is no interval certification of the complete solution, discreteness, or domain. The original dataset's knot identification is trusted; this project does not independently prove that the encoded complement belongs to the named knot.
- The integration accuracy is limited by machine-precision domain construction. The tetrahedral solve is performed at 120-digit working precision and separately compared with 160 digits.

## Sources

- [Pinned knot dataset](https://github.com/3-manifolds/snappy_15_knots/blob/f3eb9cdd16e1792dd84476a945315049873e8ac1/manifold_src/original_manifold_sources/knots_and_links_through_14.csv): record 44846, CSV line 44847. `data/provenance.json` records its URL, commit, and SHA-256.
- [Futer and Gueritaud, From angled triangulations to hyperbolic structures](https://arxiv.org/abs/1004.0440): angle-space volume maximization and completeness.
- Core implementation reconstructed from the shared chat, then repaired and tested locally. Tests do not rely on the unavailable prior Regina export; reciprocity, link topology, an independent figure-eight example, and independent integration are checked directly here.

## Additional regression: K5a1

`tests/TestK5a1.wl` runs the complete pipeline on the dataset's three-tetrahedron
`K5a1` complement, using signature `dLQcbcciirv_BacB`. All 12 numerical checks
passed, including an independent 160-digit solve and domain integration.
The volume is `2.82812208833078316276389880927663494277...`; the candidate
domain has 45 vertices, 69 edges, and 26 faces. Domain integration differs
by approximately `1.17e-11`. Results and a rotatable notebook are in
`outputs/K5a1/`. This test uses the same unchanged geometry package.

## Fresh SnapPy comparison: 10 samples

A local `.venv` was created using
`/Library/Frameworks/Python.framework/Versions/3.12/bin/python3` (Python 3.12.10),
with SnapPy 3.3.2. Installed versions are recorded in `tests/requirements-snappy.txt`.
SnapPy is used only by this comparison harness; the Wolfram geometry package
remains independent of it.

The ten preselected samples are K4a1, K5a1, K6a1, K7a1, K8a1, K9a1,
K10a1, K11n1, K12n1, and K14n12345. They span 2–20 tetrahedra.
The comparison uses freshly computed `Manifold.high_precision().volume()`
values from both the original signature and the knot name, against fresh
120-digit Wolfram solves. The fixed absolute comparison tolerance is 1e-30.
All ten passed, including the Wolfram positivity, angle, complex gluing,
stationarity, and independent tetrahedral volume formula checks. This batch
checks volumes; it does not construct ten Dirichlet domains or certify results.

Reproduce from the project directory:

```sh
.venv/bin/python tests/CompareSnapPy.py prepare
/Applications/Wolfram.app/Contents/MacOS/WolframKernel -script "$PWD/tests/CompareSnapPy.wl"
.venv/bin/python tests/CompareSnapPy.py report
```

See `outputs/snappy-comparison/comparison.md`, `comparison.csv`, and
`comparison.json` for the complete table. Raw engine results and the exact
sample records are retained in the same directory.

Full package documentation: [docs/Hyperbolic3Manifolds.md](docs/Hyperbolic3Manifolds.md).
