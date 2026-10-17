# Hyperbolic3Manifolds — package documentation

`src/Hyperbolic3Manifolds.wl` is a Wolfram Language package that takes a cusped 3-manifold given as an ideal triangulation and computes its complete hyperbolic structure, holonomy, a candidate Dirichlet domain, and its volume (computed in two independent ways). It uses no SnapPy, SnapPea, Regina, or Python. The only outside input is the combinatorial triangulation from a public dataset.

This document covers:

1. [Background](#1-background): the geometry the package relies on.
2. [Quick start](#2-quick-start)
3. [Pipeline overview](#3-pipeline-overview)
4. [Function reference](#4-function-reference)
5. [Conventions](#5-conventions)
6. [Worked examples and validation](#6-worked-examples-and-validation)
7. [Scope and limitations](#7-scope-and-limitations)
8. [How the package came about](#8-how-the-package-came-about)

---

## 1. Background

### 1.1 Triangulated 3-manifolds

The package builds a 3-manifold from tetrahedra $\Delta_1,\dots,\Delta_N$ by gluing their triangular faces in pairs with face-pairing maps $\phi_\alpha : F_\alpha \to F'_\alpha$:

$$M = \Big(\bigsqcup_{j=1}^{N} \Delta_j\Big)\Big/\sim, \qquad p \sim \phi_\alpha(p).$$

Only *which* faces are paired, and *which vertices* each pairing matches, determine $M$. The order in which the gluings are carried out does not matter. Such a triangulation is "generalized": edges and vertices of one tetrahedron can be identified with each other.

In an **ideal** triangulation the tetrahedron vertices are removed. Cutting off a small corner at each removed vertex leaves triangles, and these triangles glue into the **vertex link**. When the link is a torus, the removed vertex is a **cusp**, an infinitely long end whose cross-sections are tori. A hyperbolic knot complement $S^3 \setminus K$ has exactly one torus cusp, which comes from the removed knot.

### 1.2 Hyperbolic space and ideal tetrahedra

In the upper-half-space model,

$$\mathbb H^3 = \{(x,y,t) : t>0\}, \qquad ds^2 = \frac{dx^2+dy^2+dt^2}{t^2}, \qquad dV = \frac{dx\,dy\,dt}{t^3}.$$

The horizontal coordinates combine into a complex number $w=x+iy$. The ideal boundary $t=0$ is infinitely far away, and together with a point $\infty$ it forms $\mathbb C\cup\{\infty\}$. This is the sphere that bounds the Poincaré ball, just as the circle bounds the Poincaré disk. Geodesics are vertical lines and semicircles perpendicular to the boundary.

An **ideal tetrahedron** is the convex hull of four distinct ideal points. An isometry can move three of its vertices to $\infty, 0, 1$. The fourth vertex then lands at a complex number $z$ with $\operatorname{Im} z>0$, the **shape parameter**. For ordered vertices $a,b,c,d$ the shape is the cross ratio

$$z = \frac{(d-b)(c-a)}{(d-a)(c-b)}.$$

The three pairs of opposite edges carry the shapes $z,\ \tfrac{1}{1-z},\ \tfrac{z-1}{z}$. Their arguments are the dihedral angles $\alpha,\beta,\gamma$, and $\alpha+\beta+\gamma=\pi$. Despite its infinite extent, the tetrahedron has finite volume:

$$\operatorname{Vol} = \Lambda(\alpha)+\Lambda(\beta)+\Lambda(\gamma), \qquad \Lambda(\theta) = -\int_0^\theta \log|2\sin u|\,du = \tfrac12\operatorname{Im}\operatorname{Li}_2(e^{2i\theta}).$$

Equivalently, $\operatorname{Vol} = D(z) = \operatorname{Im}\operatorname{Li}_2(z) + \arg(1-z)\log|z|$ (the Bloch–Wigner dilogarithm).

The regular ideal tetrahedron has $z=\tfrac12+\tfrac{\sqrt3}{2}i$, all angles $\pi/3$, and volume $3\Lambda(\pi/3)\approx 1.0149416064$. The figure-eight knot complement `m004` is built from two of them, so its volume is $\approx 2.0298832128$.

### 1.3 From angles to a complete structure

Every tetrahedron must have positive dihedral angles that sum to $\pi$, and the angles around each glued edge must sum to $2\pi$. These linear conditions cut out the **angle structure space**. By the Casson–Rivin theorem (see Futer–Guéritaud, [arXiv:1004.0440](https://arxiv.org/abs/1004.0440)), a point in the interior of this space that maximizes total volume gives the complete hyperbolic structure. This is why the package maximizes volume rather than solving only the edge equations: edge equations alone need not give a *complete* structure.

### 1.4 Holonomy and the Dirichlet domain

Moving from one tetrahedron across a face to the next applies a Möbius transition map $g_i \in \mathrm{PSL}(2,\mathbb C)$. Composing these maps along closed paths gives the holonomy representation $\rho:\pi_1(M)\to\mathrm{PSL}(2,\mathbb C)$, and $M = \mathbb H^3/\Gamma$. The order of the face crossings matters because the $g_i$ do not commute.

The **Dirichlet domain** centered at a basepoint $o$ is
$D = \{x : d(x,o)\le d(x,\gamma o)\ \forall \gamma\in\Gamma\}$.
In the Klein model, each bisector is a flat plane, so $D$ is a convex Euclidean polyhedron inside the unit ball. Its faces come in pairs matched by the generators. Its hyperbolic volume is $\int_D (1-|k|^2)^{-2}\,d^3k$ in Klein coordinates, which equals $\int_D 8(1-|p|^2)^{-3}\,d^3p$ in Poincaré coordinates.

---

## 2. Quick start

Requires Wolfram 15.0.1 or later. Load the package with an absolute path:

```wolfram
Get["/absolute/path/Hyperbolic3Manifolds/src/Hyperbolic3Manifolds.wl"];

t = DecodeTriangulation["cPcbbbiht"];          (* figure-eight knot complement *)
ValidateIdealTriangulation[t]
(* <|"Cusps" -> 1, "VertexLinkEulerCharacteristics" -> {0}, "ReversedEdges" -> False|> *)

s = SolveCompleteStructure[t, 80, 25];
N[s["Volume"], 20]                               (* 2.0298832128193072500 *)

h = BuildHolonomy[t, s];
d = BuildDirichletDomain[h];                     (* 42 vertices, 64 edges, 24 faces *)
i = IntegrateDomainVolume[d, 8];
i["Volume"] - s["Volume"]                        (* ~3.6*10^-9; domain geometry is machine precision *)

DomainGraphics[d, "Poincare"]
```

To run the full K14n12345 computation and all test suites from a terminal (the script must be given an absolute path):

```sh
/Applications/Wolfram.app/Contents/MacOS/WolframKernel -script "$PWD/tests/RunTests.wl"
```

---

## 3. Pipeline overview

```
isomorphism signature (String)
        │ DecodeTriangulation
        ▼
triangulation  t ──► ValidateIdealTriangulation   (cusps, torus links)
        │        └─► AngleSystem                  (exact linear constraints)
        │ SolveCompleteStructure
        ▼
structure  s   (angles, shapes, volume, residuals)
        │ BuildHolonomy[t, s]
        ▼
holonomy   h   (PSL(2,C) face-pairing generators)
        │ BuildDirichletDomain
        ▼
domain     d   (Klein-model polyhedron, face pairings, checks)
        ├─► IntegrateDomainVolume   (independent volume)
        └─► DomainGraphics          (Poincaré / Klein rendering)
```

Every stage takes and returns an `Association`. The stages that can fail return a `Failure[tag, details]` instead (see [failure tags](#46-failure-tags)), so check with `AssociationQ` or `FailureQ` before continuing. The test suites check `AssociationQ` before each stage, so a failure shows up as failed tests.

The `Run14n12345.wlt` suite saves intermediate results as WXF files in `outputs/` (`structure.wxf`, `holonomy.wxf`, `domain.wxf`, `domain-integral.wxf`). Later scripts reload these files instead of recomputing.

---

## 4. Function reference

### 4.1 `DecodeTriangulation[sig]`

Decodes a **classic, connected 3D isomorphism signature** (Regina/SnapPy format) into face pairings.

- Base-64 alphabet `a–z A–Z 0–9 + -`. The first character gives the tetrahedron count; `63` switches to wide encoding.
- Facet actions use 0 (boundary), 1 (gluing to a new tetrahedron), or 2 (gluing to an existing one). Destinations and permutations follow, with permutation indices into the lexicographically sorted $S_4$.
- Anything after `_` is peripheral (cusp) decoration. It is stored but **not decoded**.
- Orientations are propagated from tetrahedron 0. A gluing whose permutation sign disagrees with the propagated orientation is rejected.

Returns:

| Key | Meaning |
|---|---|
| `"Signature"` | the input string |
| `"Tetrahedra"` | $N$ |
| `"FacePairings"` | list of $4N$ associations `<|"tetrahedron", "face", "neighbor", "vertex_permutation"|>`, all **0-based**; `vertex_permutation[[v+1]]` is the image of vertex `v` |
| `"Orientations"` | list of $\pm1$, one per tetrahedron |
| `"PeripheralDecoration"` | text after `_`, or `None` |

Failure tags: `EmptySignature`, `InvalidAlphabet`, `TruncatedSignature`, `EmptyTriangulation`, `InvalidFacetAction`, `InvalidPadding`, `FacetCountMismatch`, `BoundaryFacesUnsupported`, `TrailingSignatureData`, `InvalidGluingIndex`, `MissingFacetAction`, `MissingJoin`, `InvalidDestination`, `InvalidFacePair`, `SelfPairedFace`, `DisconnectedOrMalformed`, `NonOrientableTriangulation`.

### 4.2 `ValidateIdealTriangulation[t]`

Builds three graphs on the tetrahedron corners: vertex classes (cusps), oriented edge classes, and link sides. From these it computes the Euler characteristic of each vertex link, $\chi = V - E + F$ on the link triangulation. It also checks that no edge is glued to itself with reversed orientation.

Returns `<|"Cusps" -> k, "VertexLinkEulerCharacteristics" -> {0, ...}, "ReversedEdges" -> False|>`.
Fails with `ReversedEdge`, or with `NonTorusVertexLinks` (whose details include `"EulerCharacteristics"`) if any link has $\chi \ne 0$.

### 4.3 `AngleSystem[t]`

Builds the exact integer linear system on the $3N$ angles, in units of $\pi$:

- one row per tetrahedron: $\theta_{j,1}+\theta_{j,2}+\theta_{j,3} = 1$;
- one row per edge class: the sum of angles at that edge equals $2$.

| Key | Meaning |
|---|---|
| `"Matrix"` | full constraint matrix $A$ (tetrahedron rows first, then edge rows) |
| `"RightHandSideInPiUnits"` | $b$ |
| `"EdgeMatrix"` | edge rows only; also used for the complex gluing equations |
| `"EdgeClasses"` | connected components of the 6N tetrahedron edges |
| `"NullSpace"` | exact basis of $\ker A$, the directions the angles can move |

For K14n12345: 60 angles, rank 39, 21-dimensional null space.

### 4.4 `SolveCompleteStructure[t, wp:120, goal:45]`

Finds the interior maximum of the volume functional on angle structure space.

1. Runs `ValidateIdealTriangulation`. If it fails, that failure is returned.
2. Finds a strictly positive starting point with `LinearOptimization`, which maximizes the smallest angle $h$. Fails with `NoStrictAngleStructure` if $h \le 0$.
3. Takes Newton steps in the null space at working precision `wp`. The gradient is $-B\log(2\sin\theta)$ and the Hessian is $-B\,\operatorname{diag}(\cot\theta)\,B^T$. A backtracking line search keeps $0<\theta<\pi$ and enforces an Armijo-type increase. It stops when $\max|\nabla| < 10^{-\text{goal}}$, after at most 80 iterations.
4. Converts angles to shapes, $z = \dfrac{\sin\theta_2}{\sin\theta_3}e^{i\theta_1}$, and conjugates the shape for negatively oriented tetrahedra.
5. Checks the complex edge equations $\prod z^{\pm1} = 1$ through logarithms.
6. Computes the volume three ways: the Lobachevsky sum, Bloch–Wigner, and direct `NIntegrate` of $-\log(2\sin u)$.

Requires `wp >= 2 goal + 20`.

| Key | Meaning |
|---|---|
| `"Angles"` | $3N$ angles (radians, precision `wp`) |
| `"UnsignedShapes"` | $z$ per tetrahedron |
| `"ShapesInOriginalLabels"` | shapes corrected for orientation; used by `BuildHolonomy` |
| `"Volume"` | $\sum\Lambda(\theta)$ |
| `"BlochWignerVolume"`, `"QuadratureVolume"` | independent volume formulas |
| `"GradientResidual"` | stationarity residual |
| `"AngleEquationResidual"` | $\max|A\theta-\pi b|$ |
| `"ComplexEdgeResidual"` | $\max|\prod z^{\pm1}-1|$ |
| `"MinimumAngle"`, `"WorkingPrecision"`, `"RequestedGoal"` | diagnostics |
| `"History"` | per-iteration volume, residual, and step fraction |
| `"AngleSystem"` | the `AngleSystem[t]` result |

Failure tags: `InsufficientWorkingPrecision`, `NoStrictAngleStructure`, `NewtonLineSearchFailed`, `NoInteriorCriticalPoint` (with `"Residual"`), `ComplexEdgeEquationsFailed`.

A failure here does **not** prove the manifold is non-hyperbolic. It only means this solver found no interior maximum for this triangulation.

### 4.5 `BuildHolonomy[t, s]`

Places each tetrahedron with vertices $(\infty, 0, 1, z)$, written as projective vectors `{1,0}, {0,1}, {1,1}, {z,1}`. For every face pairing, `tripleMap` solves for the $\mathrm{SL}(2,\mathbb C)$ matrix that matches the three shared vertices. A spanning-tree development from tetrahedron 0 gives each tetrahedron a developing map. Each face pairing then yields the generator
$g = \operatorname{dev}_j \cdot \operatorname{trans} \cdot \operatorname{dev}_k^{-1}$.

The generators are conjugated so that the basepoint $(1/2,\,1/3,\,1)$ in upper half space becomes $(0,0,1)$, which corresponds to the center of the ball model. Identity elements and duplicates up to sign ($\pm g$) are removed.

Returns `<|"Generators", "DevelopingMaps", "FaceTransitions", "BasepointUpperHalfSpace" -> {1/2, 1/3, 1}|>`.

### 4.6 `BuildDirichletDomain[h, maxIterations:12]`

Builds a candidate Dirichlet domain in the Klein ball.

- The image of the basepoint under $g$ in hyperboloid coordinates is $(q_0, q)$, read from $gg^*$. Its bisector is the half-space $q\cdot k \le q_0 - 1$, with normal $n = q/(q_0-1)$, so $D=\{k : n\cdot k \le 1\}$.
- Each iteration takes the convex hull of the normals (the polar polyhedron), keeps the generators whose normals are hull vertices (the *active* faces), and computes the domain's vertices. It then adds products $a\cdot b$ of active generators whose bisectors cut off a current vertex. The loop stops when no new cut appears.
- It then checks: vertices lie in the closed ball and satisfy every half-space; Euler characteristic $V-E+F=2$; every face has an inverse face and the generator maps the face's vertices onto it; the dihedral angles in each edge cycle sum to $2\pi$.

| Key | Meaning |
|---|---|
| `"Vertices"` | Klein coordinates (machine precision) |
| `"Normals"`, `"Generators"` | one per face, in the same order as `"Faces"` |
| `"Faces"` | vertex indices, ordered counterclockwise around each face |
| `"Edges"` | sorted vertex-index pairs |
| `"FacePairs"` | `FacePairs[[i]]` is the face that generator `i` maps face `i` onto; it is an involution |
| `"EdgeClasses"` | edge cycles under the face pairings |
| `"PairingVertexResidual"`, `"EdgeCycleAngleResidual"` | numerical checks (expected below $10^{-7}$) |
| `"IdealVertices"` | indices of vertices on the unit sphere |
| `"History"` | per-iteration face, vertex, and new-cut counts |
| `"Status"` | `"Numerically checked candidate; not certified"` |

Failure tags: `DegeneratePolarHull`, `DomainDidNotStabilize`, `DomainExtendsOutsideBall`, `HalfSpaceViolation`, `DegenerateFace`, `PolyhedronEulerCheckFailed`, `MissingInverseFace`, `FacePairingMismatch`, `PairingVertexResidualTooLarge`, `InvalidPolyhedronEdge`, `EdgeCycleAngleCheckFailed`.

### 4.7 `IntegrateDomainVolume[d, goal:8]`

Computes the volume of the domain without using the tetrahedra. The radial field $F(k)=f(r)\,k$ with

$$f(r) = \frac{r/(1-r^2) - \operatorname{arctanh} r}{2r^3}$$

has divergence $(1-|k|^2)^{-2}$, the Klein volume density. By the divergence theorem, the volume becomes a flux integral over the faces. Each face is split into triangles around its centroid and integrated with `NIntegrate` at 30 digits, with accuracy and precision goal `goal` per triangle. The singularities at ideal vertices are integrable. Ideal vertices are snapped onto the unit sphere first.

Returns `<|"Volume", "Triangles", "PerTriangleGoal", "GeometryPrecision" -> "Machine precision", "TriangleIntegrals"|>`.

The agreement with `s["Volume"]` is limited by the machine-precision domain geometry (about $10^{-10}$ to $10^{-11}$), not by the quadrature goal.

### 4.8 `DomainGraphics[d, model:"Poincare"]`

Returns a rotatable `Graphics3D` of the domain. Use `"Klein"` for straight edges. `"Poincare"` maps points with $p = k/(1+\sqrt{1-|k|^2})$, so faces and edges appear curved. Faces are drawn translucent blue, ideal vertices orange, and the basepoint (the center) gray.

### 4.9 Failure tags

All failures are `Failure[tag, details]` objects thrown inside `Catch`. Each section above lists its function's tags. `SolveCompleteStructure` passes on any failure from `ValidateIdealTriangulation`.

---

## 5. Conventions

- **Indexing.** Tetrahedra, faces, and vertices in `"FacePairings"` are 0-based. Face `f` is the face opposite vertex `f`.
- **Angle order.** Angles are stored three per tetrahedron. Angle 1 sits on edges 01 and 23, angle 2 on edges 02 and 13, angle 3 on edges 03 and 12.
- **Shapes.** $z_j = \dfrac{\sin\theta_{j,2}}{\sin\theta_{j,3}}\,e^{i\theta_{j,1}}$ is the shape on edges 01/23. The other two edge types carry $1/(1-z)$ and $(z-1)/z$.
- **Precision.** Tetrahedral solves use high working precision (`wp=120, goal=45` by default; the precision check uses `160, 65`). Holonomy is computed at that precision. `BuildDirichletDomain` works at **machine precision** (`N[...]`).
- **Thresholds used in tests.** Structure residuals $<10^{-40}$; stationarity $<10^{-45}$; the three volume formulas agree to $<10^{-40}$; domain residuals $<10^{-9}$; domain integral vs tetrahedral volume $<10^{-7}$.

---

## 6. Worked examples and validation

### 6.1 Direct integral for `m004` (figure-eight)

This calculation came before the package. Put one regular tetrahedron at vertices $0, 1, \tfrac12+\tfrac{\sqrt3}{2}i, \infty$. It is the region above the hemisphere $(x-\tfrac12)^2+(y-\tfrac{\sqrt3}{6})^2+t^2=\tfrac13$ over the equilateral triangle. Integrating $dt/t^3$ and using the triangle's symmetry gives

```wolfram
vTet = NIntegrate[Sqrt[3] Log[2 (1 + r)/((1 - r) (1 + 3 r))]/(1 + 3 r^2), {r, 0, 1},
  WorkingPrecision -> 60, AccuracyGoal -> 45, PrecisionGoal -> 45, MaxRecursion -> 40];
N[2 vTet, 45]   (* 2.02988321281930725004240510854904057188337861506 *)
```

This agrees with $-6\int_0^{\pi/3}\log(2\sin\theta)\,d\theta$ and $2\operatorname{Im}\operatorname{Li}_2(e^{i\pi/3})$. The test suite repeats this check through the package: `SolveCompleteStructure[DecodeTriangulation["cPcbbbiht"], 80, 25]` agrees with $2\operatorname{Im}\operatorname{Li}_2(e^{i\pi/3})$ to $10^{-24}$.

### 6.2 K14n12345 (main target)

The input is record 44846 (CSV line 44847) of the pinned [`snappy_15_knots`](https://github.com/3-manifolds/snappy_15_knots/blob/f3eb9cdd16e1792dd84476a945315049873e8ac1/manifold_src/original_manifold_sources/knots_and_links_through_14.csv) dataset, with signature `uvvzwPwMAzPAQQchellhjokjqqsprtprtrstavtlgolkkpdbgclbotcbl_BaiB`. `data/provenance.json` records the commit and SHA-256.

| Quantity | Value |
|---|---|
| Tetrahedra / cusps | 20 / 1 torus cusp |
| Angle system | rank 39 on 60 angles, 21-dim null space |
| Volume | `18.36536110161047534340644954313593224436235757255441338977` |
| Residuals (stationarity, edge) | ~$10^{-68}$ |
| Dirichlet domain | 161 vertices, 243 edges, 84 faces, 1 ideal vertex |
| Domain integral | `18.3653611015266` (difference ~$8.4\times10^{-11}$) |
| 160-digit re-solve | agrees to 60 decimal places |
| Tests | 38/38 pass across five suites (`outputs/tests.json`) |

Results: `outputs/results.json`, `outputs/14n12345-Wolfram.nb` (rotatable Poincaré and Klein views), and `outputs/domain-preview.png`.

### 6.3 K5a1 (regression, unchanged package)

Signature `dLQcbcciirv_BacB`, 3 tetrahedra. All 12 checks in `tests/TestK5a1.wl` pass. The volume is `2.82812208833078316276389880927663494277…`. The domain has 45 vertices, 69 edges, and 26 faces, and the integral differs by about $1.17\times10^{-11}$. Results are in `outputs/K5a1/`.

### 6.4 Comparison with SnapPy (10 samples)

`tests/CompareSnapPy.py` runs SnapPy 3.3.2 in a separate `.venv` (Python 3.12) and computes `Manifold.high_precision().volume()` from both the signature and the knot name. `tests/CompareSnapPy.wl` solves the same records independently at 120 digits. All ten samples agree within a tolerance of $10^{-30}$: K4a1, K5a1, K6a1, K7a1, K8a1, K9a1, K10a1, K11n1, K12n1, and K14n12345 (2–20 tetrahedra). This batch compares volumes only. No SnapPy output is ever passed into the Wolfram solver. See `outputs/snappy-comparison/comparison.md`.

```sh
.venv/bin/python tests/CompareSnapPy.py prepare
/Applications/Wolfram.app/Contents/MacOS/WolframKernel -script "$PWD/tests/CompareSnapPy.wl"
.venv/bin/python tests/CompareSnapPy.py report
```

---

## 7. Scope and limitations

- **Input class.** The package handles connected, orientable ideal triangulations with every face paired, torus vertex links, and a strictly positive angle structure with an interior volume maximum. It is not an algorithm for every 3-manifold. It rejects boundary faces, non-orientable input, and Klein-bottle or sphere links.
- **Signatures.** Only classic connected signatures are supported. Peripheral decoration is kept but not decoded, so there is no meridian/longitude, no cusp shape, and no Dehn filling.
- **Not certified.** There is no interval arithmetic. The residuals are strong numerical evidence for the complete structure, not an existence proof. Stabilizing the bisector search does not prove that all group elements were considered, so the domain is a *candidate* that passes face-pairing and edge-cycle checks. This is not a full verification by the Poincaré polyhedron theorem.
- **Domain precision.** The domain is computed at machine precision. Asking `IntegrateDomainVolume` for more digits does not make it more accurate.
- **Identity of the knot.** The package trusts the dataset's identification of the triangulation with the named knot.
- **Solver failure is not evidence.** A failure of `SolveCompleteStructure` does not prove non-hyperbolicity. Another triangulation of the same manifold may succeed.

---

## 8. How the package came about

The package grew out of a conversation that went from concept to computation:

1. **How SnapPy represents a 3-manifold.** Ideal tetrahedra glued along faces, shape parameters, gluing and completeness equations, and volume as a sum of Lobachevsky terms.
2. **First Wolfram calculation.** The volume of `m004` computed directly by integrating $dV = dx\,dy\,dt/t^3$ over a regular ideal tetrahedron (§6.1). A Dirichlet-domain picture of `m004` at this stage still used geometry taken from SnapPy.
3. **Finding data.** `KnotData` does not know 14n12345. The pinned `snappy_15_knots` CSV supplied its triangulation, which passed combinatorial audits (one torus cusp, reciprocal pairings, orientable).
4. **Side question on knot theory.** Why knots matter for all 3-manifolds: Dehn surgery (Lickorish–Wallace), with holonomy capturing the order in which a path crosses faces. The upper-half-space height $t$ is a model coordinate, not a global layering.
5. **Full Wolfram implementation.** Signature decoder, angle-space solver, holonomy, Dirichlet domain, flux-integral volume, rendering, and tests for K14n12345. No external geometry engine is used.
6. **Regression and cross-check.** K5a1 run through the unchanged package, then a fresh 10-sample SnapPy comparison in an isolated virtual environment.
