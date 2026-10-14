# Fresh SnapPy / Wolfram volume comparison

SnapPy 3.3.2; Wolfram working precision 120 digits. Absolute tolerance: 1e-30.
Samples selected in advance across 4–14 crossings. No failed samples replaced.
Both engines receive the original triangulation signature. SnapPy is also independently loaded by knot name.
This checks volumes and Wolfram gluing/stationarity diagnostics, not ten Dirichlet domains or rigorous certification.

| Manifold | Tetrahedra | SnapPy volume (rounded) | Absolute difference | Status |
|---|---:|---:|---:|---|
| K4a1 | 2 | 2.029883212819307 | 4.47E-64 | PASS |
| K5a1 | 3 | 2.828122088330783 | 2.59E-64 | PASS |
| K6a1 | 6 | 5.693021091281301 | 4.52E-66 | PASS |
| K7a1 | 8 | 7.643375172359955 | 3.45E-64 | PASS |
| K8a1 | 10 | 9.217800316021929 | 2.21E-64 | PASS |
| K9a1 | 13 | 11.954526968232034 | 1.17E-64 | PASS |
| K10a1 | 15 | 13.980041535708047 | 4.68E-65 | PASS |
| K11n1 | 11 | 9.700477476413561 | 9.93E-65 | PASS |
| K12n1 | 15 | 14.082543874268638 | 5.44E-64 | PASS |
| K14n12345 | 20 | 18.365361101610475 | 6.11E-65 | PASS |

Passed: 10/10. Full decimal strings are retained in comparison.json.
