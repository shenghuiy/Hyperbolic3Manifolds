# data

| File | In repo | Description |
|---|---|---|
| `14n12345-record.json` | yes | The K14n12345 record (record 44846, CSV line 44847), enough to run the geometry offline |
| `provenance.json` | yes | Source URL, pinned commit, and SHA-256 of the CSV |
| `knots_and_links_through_14.csv` | **no** (32 MB, gitignored) | Full knot database from [`3-manifolds/snappy_15_knots`](https://github.com/3-manifolds/snappy_15_knots) |

Get the CSV from the pinned commit `f3eb9cdd16e1792dd84476a945315049873e8ac1`:

- [View on GitHub](https://github.com/3-manifolds/snappy_15_knots/blob/f3eb9cdd16e1792dd84476a945315049873e8ac1/manifold_src/original_manifold_sources/knots_and_links_through_14.csv)
- [Direct download (raw)](https://raw.githubusercontent.com/3-manifolds/snappy_15_knots/f3eb9cdd16e1792dd84476a945315049873e8ac1/manifold_src/original_manifold_sources/knots_and_links_through_14.csv)

Save it here as `data/knots_and_links_through_14.csv`. Its SHA-256 should be
`a210bc6866a22c8d3aa533a0804d650ffb68659f83ac5dcdb3ef3e57bef59464`.
`ImportDataset.wl` downloads it automatically if it is missing.
