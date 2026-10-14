---
name: run-hyperbolic3manifolds
description: Run, test, and drive the Hyperbolic3Manifolds Wolfram package. Use when asked to run the pipeline on a knot or isomorphism signature, compute a hyperbolic volume or Dirichlet domain, render/screenshot a domain image, call a package function directly, or run the test suites.
---

Hyperbolic3Manifolds is a Wolfram Language package (`src/Hyperbolic3Manifolds.wl`) with no server or GUI. You drive it with the driver script `.claude/skills/run-hyperbolic3manifolds/driver.wl`. The driver runs the pipeline on one triangulation, prints one line per stage plus a JSON summary, and can write PNG renders of the Dirichlet domain. Paths below are relative to the repo root.

## Prerequisites

- Wolfram 15.0.1 (licensed) at `/Applications/Wolfram.app` (macOS). Nothing else is needed: there's no build step and no package install.
- Optional: the 32 MB knot CSV, for `knot <Name>` input. It's gitignored and **not present in fresh worktrees**; see `data/README.md`. In this checkout it lives at the main repo's `data/knots_and_links_through_14.csv`.

```bash
K=/Applications/Wolfram.app/Contents/MacOS/WolframKernel
```

## Run (agent path): the driver

Always pass an **absolute** script path; the driver finds the repo from its own location.

```bash
$K -script "$PWD/.claude/skills/run-hyperbolic3manifolds/driver.wl" sig cPcbbbiht --out "${TMPDIR:-/tmp}/fig8"
```

Output (about 11 s, mostly kernel startup):

```
decode: 2 tetrahedra; cusps 1, link Euler characteristics {0}
solve: volume 2.029883212819307250042405108549 (0.2 s)
holonomy: 6 generators
domain: V,E,F = {42, 64, 24} (0.4 s)
integral: domain - tetrahedral = 5.221215642333647*^-12
wrote <TMPDIR>/fig8
{ ...JSON summary... }
```

`--out` writes `summary.json`, `poincare.png` and `klein.png`. Read the PNGs to check the domain visually: you should see a translucent blue polyhedron with the ideal vertex marked orange.

| Source argument | Example |
|---|---|
| `sig <isosig>` | `sig cPcbbbiht` (figure-eight) |
| `knot <Name> --csv <path>` | `knot K6a1 --csv /Users/shenghuiyang/Developer/LowDimTopology/data/knots_and_links_through_14.csv` |
| `record <file.json>` | `record "$PWD/data/14n12345-record.json"` |

| Option | Effect |
|---|---|
| `--stop solve\|holonomy\|domain\|integral` | Last stage to run (default `integral`) |
| `--out <dir>` | Write the summary and PNG renders |
| `--wp <n> --goal <n>` | Solver working precision and goal (default 120 and 45, the project standard) |
| `--igoal <n>` | Domain-integral precision goal (default 10, as in the tests) |

Exit status is 0 on success and 1 if any stage fails. On failure the JSON summary has `FailedStage` and `Failure` keys:

```bash
$K -script "$PWD/.claude/skills/run-hyperbolic3manifolds/driver.wl" knot K3a1 --csv /Users/shenghuiyang/Developer/LowDimTopology/data/knots_and_links_through_14.csv
# solve: FAILED Failure[NoStrictAngleStructure, <||>]   (trefoil, not hyperbolic), exit 1
```

Measured run times:

| Run | Time |
|---|---|
| Figure-eight, full run | ~11 s |
| K6a1 to `--stop domain` | ~10 s |
| K14n12345 `--stop solve` | ~5 s |
| K14n12345 full run with `--out` | **~105 s**, mostly the goal-10 integral; with `--igoal 8` it's ~27 s |

## Direct invocation (one function)

For a change to one function, load the package in a script file and call that function. Use a file, not `-run` (see Gotchas).

```bash
cat > "${TMPDIR:-/tmp}/probe.wl" <<EOF
Get["$PWD/src/Hyperbolic3Manifolds.wl"];
t = DecodeTriangulation["cPcbbbiht"];
s = SolveCompleteStructure[t, 80, 25];
Print[N[s["Volume"], 20]];
Print[Keys[s]];
EOF
$K -script "${TMPDIR:-/tmp}/probe.wl"
```

## Test

```bash
$K -script "$PWD/tests/RunTests.wl" Hyperbolic3Manifolds
```

This quick suite takes about 2 s and runs 16 checks on the committed `outputs/` artifacts.

```bash
$K -script "$PWD/tests/RunTests.wl"
```

The full run recomputes K14n12345 and rewrites `outputs/`. It takes about 3 minutes and runs 31 checks across 4 suites (5 suites if the CSV is in `data/`), so run it in the background. After any edit under `src/`, a project hook blocks finishing until a full run newer than the edit has passed. Other scripts (precision check, K5a1, SnapPy comparison) are described in `tests/README.md`.

## Gotchas

- **`-run '...Get[...]; f[...]'` silently does nothing useful.** The kernel parses the whole line before `Get` runs, so `DecodeTriangulation` etc. are created in `Global`` and shadow the package (`::shdw` messages, the result comes back unevaluated). Put the code in a file and use `-script`.
- **`IntegrateDomainVolume` goal changes both the answer and the runtime.** Goal 8 gives a domain-minus-tetrahedral gap of about 8e-8 on K14n12345; goal 10 (the tests, and the README's `8.4e-11`) gives -8.4e-11 but takes about 4x longer. The domain itself is machine precision, so higher goals don't buy real accuracy.
- **Running any suite rewrites tracked files.** Even a subset run overwrites `outputs/tests.json`. A full run regenerates everything in `outputs/`; the `.wxf` files come out byte-identical, but `domain-preview.png` changes. Check `git status`, and run `git restore outputs/` unless the change is meant to update them.
- **A subset run doesn't satisfy the src/ hook.** The hook only accepts an `outputs/tests.json` that covers both `Run14n12345` and `Hyperbolic3Manifolds`.
- **Exact-zero residuals.** At 120 digits the angle-equation residual is an exact high-precision zero (`0``119.2`); `N[]` turns it into `0.`. The driver prints it as `0 (to 10^-119)` so the accuracy isn't lost.

## Troubleshooting

- **`ERROR: CSV not found: .../data/knots_and_links_through_14.csv`.** You're in a worktree, and the CSV is gitignored. Pass `--csv` with the main checkout's copy, or download it (`data/README.md`).
- **`ERROR: record not found: <Name>`.** There's no row with that exact name in the CSV. Names look like `K6a1` and `K14n12345` (case-sensitive).
