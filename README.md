[![CircleCI](https://circleci.com/gh/brendanlong/ocaml-trie.svg?style=shield)](https://circleci.com/gh/brendanlong/ocaml-trie)
[![Coverage Status](https://coveralls.io/repos/github/brendanlong/ocaml-trie/badge.svg?branch=master)](https://coveralls.io/github/brendanlong/ocaml-trie?branch=master)

This is forked from <https://www.lri.fr/~filliatr/software.en.html> for approximate string matching.

Current benchmarks:

```
┌────────────────────────────────────────────────┬────────────────┬─────────────┬─────────────┬─────────────┬────────────┐
│ Name                                           │       Time/Run │     mWd/Run │    mjWd/Run │    Prom/Run │ Percentage │
├────────────────────────────────────────────────┼────────────────┼─────────────┼─────────────┼─────────────┼────────────┤
│ populate map                                   │   572_919.04ns │  90_512.87w │   1_888.87w │   1_888.87w │     13.82% │
│ populate hash table                            │   203_260.31ns │  10_975.34w │   7_963.70w │   6_938.70w │      4.90% │
│ populate trie                                  │ 1_718_170.10ns │ 277_668.54w │  88_706.80w │  88_706.80w │     41.45% │
│ populate array trie                            │ 4_145_416.84ns │ 540_437.90w │ 105_178.14w │ 105_178.14w │    100.00% │
│ lookup keys map                                │       222.42ns │       2.00w │             │             │            │
│ lookup keys hash table                         │        98.03ns │       2.00w │             │             │            │
│ lookup keys trie                               │       323.37ns │      59.46w │             │             │            │
│ lookup keys array trie                         │       338.47ns │      72.15w │             │             │            │
│ find_approximate trie ~max_differences:0       │       345.51ns │      68.45w │             │             │            │
│ find_approximate trie ~max_differences:1       │    14_485.15ns │   1_102.91w │       0.65w │       0.65w │      0.35% │
│ find_approximate trie ~max_differences:2       │   198_593.19ns │  19_394.85w │      10.89w │      10.89w │      4.79% │
│ find_approximate trie ~max_differences:3       │   968_443.72ns │ 157_952.36w │     119.21w │     119.21w │     23.36% │
│ find_approximate array trie ~max_differences:0 │       346.59ns │      81.12w │             │             │            │
│ find_approximate array trie ~max_differences:1 │    13_187.24ns │   2_037.60w │       1.05w │       1.05w │      0.32% │
│ find_approximate array trie ~max_differences:2 │   178_434.43ns │  24_090.49w │      13.03w │      13.03w │      4.30% │
│ find_approximate array trie ~max_differences:3 │   868_875.12ns │ 187_760.13w │     150.36w │     150.36w │     20.96% │
│ find_approximate naive ~max_differences:0      │   628_038.70ns │ 369_407.67w │   2_551.67w │   2_551.67w │     15.15% │
│ find_approximate naive ~max_differences:1      │   640_129.20ns │ 385_537.75w │   2_631.62w │   2_631.62w │     15.44% │
│ find_approximate naive ~max_differences:2      │   632_311.36ns │ 391_272.72w │   2_634.63w │   2_634.63w │     15.25% │
│ find_approximate naive ~max_differences:3      │   631_650.84ns │ 376_681.94w │   2_612.15w │   2_612.15w │     15.24% │
└────────────────────────────────────────────────┴────────────────┴─────────────┴─────────────┴─────────────┴────────────┘
```

 - `trie` is using `Trie.Make(Map.Make(Char))`
 - `array trie` is using a sorted-array map for the nodes (much slower to setup, faster due to better cache usage)
 - `naive` is just looping through every word and checking the levenshtein distance
