# Hyperbolic 3-manifolds in Wolfram Language

Computes the complete hyperbolic structure, holonomy representation, Dirichlet domain and volume of a cusped hyperbolic 3-manifold from an ideal triangulation, entirely in Wolfram Language. The input is an isomorphism signature, the compact text encoding of a triangulation used by SnapPy and Regina. The geometry, linear algebra, integration and graphics are all computed here; SnapPy, Regina and Python are not called.

The main example is the complement of the knot **K14n12345** (20 ideal tetrahedra). K5a1 and the figure-eight knot are used as regressions.

## Background

### Knot complements and ideal triangulations

By Thurston's hyperbolization theorem, the complement $M = S^3 \setminus K$ of a knot that is neither a torus knot nor a satellite admits a unique complete hyperbolic metric of finite volume (unique by Mostow–Prasad rigidity). So hyperbolic invariants such as the volume are topological invariants of the knot.

Such an $M$ can be cut into **ideal tetrahedra**: tetrahedra with their vertices removed, glued face to face. The removed vertices form the cusp. A small neighbourhood of an ideal vertex is a cone on a triangle, and these triangles fit together into the **vertex link**. For a knot complement the link is a single torus (Euler characteristic 0).

### Hyperbolic ideal tetrahedra

In the upper half-space model $\mathbb{H}^3 = \{(z,t) : z \in \mathbb{C},\ t > 0\}$, an ideal tetrahedron has its four vertices on the sphere at infinity $\hat{\mathbb{C}}$. Up to isometry they are $0, 1, \infty, z$ with $\operatorname{Im} z > 0$, so a tetrahedron is determined by one complex **shape parameter** $z$. Opposite edges carry the same dihedral angle, and the three angles $\alpha, \beta, \gamma$ satisfy $\alpha + \beta + \gamma = \pi$. Its volume is

$$\operatorname{vol} = \Lambda(\alpha) + \Lambda(\beta) + \Lambda(\gamma), \qquad \Lambda(\theta) = -\int_0^\theta \log|2\sin u|\,du,$$

where $\Lambda$ is the Lobachevsky function.

### From angles to the complete structure

An **angle structure** assigns positive angles to every tetrahedron so that each tetrahedron's angles sum to $\pi$ and the angles around each edge of the triangulation sum to $2\pi$. These are linear conditions, so the angle structures form an open convex polytope $\mathcal{A}$. The Casson–Rivin theorem says the volume functional $\mathcal{V} = \sum \Lambda$ is strictly concave on $\mathcal{A}$, and that an interior critical point gives shapes satisfying both the gluing equations (the shapes around every edge multiply to 1) and the cusp completeness equations. So the hyperbolic structure is found by maximizing a concave function on a polytope, instead of solving the nonlinear gluing equations directly. Solving only the edge equations would give a hyperbolic structure that may be incomplete, which is why the volume maximization is used.

### Holonomy and the Dirichlet domain

Developing the tetrahedra into $\mathbb{H}^3$ turns each face gluing into an isometry of $\mathbb{H}^3$, that is, an element of $\mathrm{PSL}(2,\mathbb{C})$. These generate the **holonomy group** $\Gamma \cong \pi_1(M)$, and $M = \mathbb{H}^3/\Gamma$. Given a basepoint $x$, the **Dirichlet domain**

$$D = \{\, y \in \mathbb{H}^3 : d(y, x) \le d(y, \gamma x) \text{ for all } \gamma \in \Gamma \,\}$$

is a convex fundamental polyhedron for $\Gamma$. Its faces come in pairs identified by group elements. In the Klein model each bisector is a flat plane, so $D$ is a convex Euclidean polyhedron in the unit ball, and its volume can be integrated directly. That gives a second, independent computation of $\operatorname{vol}(M)$.

## Algorithm

1. **Decode the signature.** Read the base-64 encoding of face pairings and vertex permutations, rebuild reciprocal face identifications, and orient the tetrahedra. The peripheral (meridian/longitude) decoration after `_` is kept but not decoded.
2. **Check the topology.** Build the vertex-link triangles and their gluings, reject reversed edges, and require every cusp link to have Euler characteristic 0. K14n12345 has one torus cusp.
3. **Build the angle space.** The constraints form an exact integer matrix. For K14n12345 it has rank 39 on 60 angles, leaving 21 deformation directions. Linear programming finds a strictly positive starting point.
4. **Maximize volume.** Newton's method on $\sum\Lambda$, restricted to the exact nullspace of the constraint matrix, at 120-digit working precision. The solver reports angle-equation, gradient and complex-gluing residuals and checks the volume against both the Bloch–Wigner formula and direct quadrature.
5. **Build the holonomy.** Convert angles to shapes and develop adjacent tetrahedra by Möbius maps fixed by three ideal vertices. Along a spanning tree this leaves face-pairing generators in $\mathrm{PSL}(2,\mathbb{C})$. The basepoint is $(1/2, 1/3, 1)$ in upper half-space, which becomes the centre of the ball.
6. **Build a candidate Dirichlet domain.** If the hyperboloid image of the basepoint under an isometry is $(q_0, q)$, its Klein bisector halfspace is $q \cdot k \le q_0 - 1$. Intersect halfspaces with a polar convex hull and keep adding products of the currently active generators until the polyhedron stops changing. Then check that faces pair up, that paired vertices map to each other, the Euler characteristic, and that the dihedral angles around each edge cycle sum to $2\pi$. This step is machine precision.
7. **Integrate independently.** The Klein volume density is $(1-|k|^2)^{-2}$. The radial field $F(k) = f(r)\,k$ with

   $$f(r) = \frac{r/(1-r^2) - \operatorname{artanh} r}{2r^3}$$

   has exactly this divergence, so by the divergence theorem the volume is a sum of flux integrals over triangulated faces of $D$. The singularities at ideal vertices are integrable. This uses only the domain's coordinates, not the tetrahedral volumes.
8. **Draw.** Klein edges are straight. The map $p = k/(1+\sqrt{1-|k|^2})$ gives the Poincaré ball view, where edges and faces are curved.

## Results for K14n12345

Tetrahedral volume (120-digit solve, stable when re-solved at 160 digits):

```
18.36536110161047534340644954313593224436235757255441338977
```

The Dirichlet domain has **161 vertices, 243 edges and 84 faces**, with one ideal vertex. Its independently integrated volume is about `18.3653611015266`, which differs from the tetrahedral sum by about `8.4e-11`. Extra digits in the integral add no accuracy, because the domain is built at machine precision.

Open `outputs/14n12345-Wolfram.nb` in Wolfram Desktop for rotatable Poincaré and Klein views. `outputs/results.json` holds the numerical diagnostics, and the `.wxf` files in `outputs/` hold the shapes, holonomy matrices, domain and integral.

## Running

Requires Wolfram 15.0.1 or later. Load the package from an absolute path:

```wolfram
Get["/absolute/path/to/src/Hyperbolic3Manifolds.wl"];

t = DecodeTriangulation["cPcbbbiht"];        (* figure-eight knot complement *)
ValidateIdealTriangulation[t]
s = SolveCompleteStructure[t, 120, 45];      (* working precision, precision goal *)
N[s["Volume"], 20]                           (* 2.0298832128193072500 *)
h = BuildHolonomy[t, s];
d = BuildDirichletDomain[h];
IntegrateDomainVolume[d, 8]["Volume"] - s["Volume"]
DomainGraphics[d, "Poincare"]
```

Each function takes and returns an `Association`, or returns a `Failure` when the input is outside the supported scope. To reproduce the K14n12345 computation and every check from a terminal:

```sh
/Applications/Wolfram.app/Contents/MacOS/WolframKernel -script "$PWD/tests/RunTests.wl"
```

The tests, the precision check, the K5a1 regression and the SnapPy comparison are described in [`tests/README.md`](tests/README.md). The full function reference is in [`docs/Hyperbolic3Manifolds.md`](docs/Hyperbolic3Manifolds.md).

## External data

### The knot dataset

Triangulations come from the knot and link census in [`3-manifolds/snappy_15_knots`](https://github.com/3-manifolds/snappy_15_knots), pinned to commit `f3eb9cdd16e1792dd84476a945315049873e8ac1`. The file `knots_and_links_through_14.csv` (32 MB) is **not stored in this repository**:

- [View on GitHub](https://github.com/3-manifolds/snappy_15_knots/blob/f3eb9cdd16e1792dd84476a945315049873e8ac1/manifold_src/original_manifold_sources/knots_and_links_through_14.csv)
- SHA-256 `a210bc6866a22c8d3aa533a0804d650ffb68659f83ac5dcdb3ef3e57bef59464`, also recorded in `data/provenance.json`

```sh
curl -L -o data/knots_and_links_through_14.csv https://raw.githubusercontent.com/3-manifolds/snappy_15_knots/f3eb9cdd16e1792dd84476a945315049873e8ac1/manifold_src/original_manifold_sources/knots_and_links_through_14.csv
```

```sh
shasum -a 256 data/knots_and_links_through_14.csv
```

The K14n12345 row (record 44846, CSV line 44847) is already saved in `data/14n12345-record.json`, so the main computation runs offline without the CSV.

Each row has the columns `id, name, cusps, DT, betti, torsion, volume, chernsimons, tets, hash, triangulation`. Only `triangulation`, the isomorphism signature, is used as input. The rounded `volume` is used only for comparison.

### Running another knot from the CSV

The CSV holds links as well as knots. At the pinned commit no row contains a quoted field, so the helper below splits rows on commas and refuses any quoted row instead of attempting general CSV parsing:

```wolfram
Get["/absolute/path/to/src/Hyperbolic3Manifolds.wl"];

findKnot[file_, name_] := Module[{s = OpenRead[file], keys, line, row = Missing["NotFound"]},
  keys = StringSplit[ReadLine[s], ","];
  While[(line = ReadLine[s]) =!= EndOfFile,
   If[StringContainsQ[line, "," <> name <> ","] && ! StringContainsQ[line, "\""],
    row = AssociationThread[keys, StringSplit[line, ","]]; Break[]]];
  Close[s]; row];

r = findKnot["/absolute/path/to/data/knots_and_links_through_14.csv", "K6a1"];
t = DecodeTriangulation[r["triangulation"]];
ValidateIdealTriangulation[t]
s = SolveCompleteStructure[t, 120, 45];
{N[s["Volume"], 30], r["volume"]}       (* 5.69302109128130076511248327748, "5.6930210913" *)
d = BuildDirichletDomain[BuildHolonomy[t, s]];
Length /@ Lookup[d, {"Vertices", "Edges", "Faces"}]   (* {74, 112, 40} *)
```

The same works for a signature from anywhere else, for example `M.triangulation_isosig()` in SnapPy or `isoSig()` in Regina: pass the string to `DecodeTriangulation`. Before trusting a result, check the residuals in `s` (`AngleEquationResidual`, `GradientResidual`, `ComplexEdgeResidual`) and in `d` (`PairingVertexResidual`, `EdgeCycleAngleResidual`) against the thresholds in [`tests/README.md`](tests/README.md).

Unsupported input fails explicitly. For example, the trefoil `K3a1` is a torus knot and not hyperbolic, and `SolveCompleteStructure` returns `Failure["NoStrictAngleStructure", ...]`.

## Scope and limitations

- Input must be a connected, orientable ideal triangulation with every face paired, torus cusps, and a strictly positive angle structure with an interior volume maximum. Boundary faces, non-orientable input and triangulations with no strict angle structure are rejected. This is not an algorithm for every 3-manifold, and a solver failure does not prove the manifold is not hyperbolic; another triangulation may succeed.
- The decoder handles classic connected isomorphism signatures. Newer signature variants and cusp decorations are not decoded.
- Results are numerical evidence, not proofs. There is no interval certification of the shapes, of discreteness, or of the domain. The bisector search stops when the polyhedron stabilizes, which does not by itself show that every group element has been considered; the face and edge checks and the agreement of the two volume computations are strong checks, not a certified Poincaré polyhedron theorem verification.
- The dataset's identification of each triangulation with a named knot is trusted, not re-proved.

## References

- W. P. Thurston, *The Geometry and Topology of Three-Manifolds*, Princeton lecture notes (1980).
- D. Futer and F. Guéritaud, [From angled triangulations to hyperbolic structures](https://arxiv.org/abs/1004.0440), Contemporary Mathematics 541 (2011). Angle structures, the volume functional and completeness.
- [`3-manifolds/snappy_15_knots`](https://github.com/3-manifolds/snappy_15_knots): source of the knot triangulations.
