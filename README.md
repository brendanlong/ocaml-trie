[![CircleCI](https://circleci.com/gh/brendanlong/ocaml-trie.svg?style=shield)](https://circleci.com/gh/brendanlong/ocaml-trie)
[![Coverage Status](https://coveralls.io/repos/github/brendanlong/ocaml-trie/badge.svg?branch=master)](https://coveralls.io/github/brendanlong/ocaml-trie?branch=master)

This is forked from <https://www.lri.fr/~filliatr/software.en.html> for approximate string matching.

Current benchmarks:

```
┌───────────────────────────────────────────────┬────────────────┬──────────────┬───────────────┬───────────────┬────────────┐
│ Name                                          │       Time/Run │      mWd/Run │      mjWd/Run │      Prom/Run │ Percentage │
├───────────────────────────────────────────────┼────────────────┼──────────────┼───────────────┼───────────────┼────────────┤
│ populate map                                  │       481.14us │      88.65kw │     1_867.09w │     1_867.09w │      0.04% │
│ populate hash table                           │       178.15us │      10.61kw │     7_418.49w │     6_393.49w │      0.01% │
│ populate trie                                 │       578.33us │     138.55kw │    11_034.72w │    11_034.72w │      0.04% │
│ populate fast trie                            │     1_038.50us │     203.42kw │    12_190.13w │    12_190.13w │      0.08% │
│ populate list trie                            │       803.12us │     203.42kw │    12_032.31w │    12_032.31w │      0.06% │
│ lookup keys map                               │       181.31us │       5.00kw │        47.61w │        47.61w │      0.01% │
│ lookup keys hash table                        │        43.38us │       5.00kw │        49.34w │        49.34w │            │
│ lookup keys trie                              │       177.65us │      22.89kw │        17.82w │        17.82w │      0.01% │
│ lookup keys fast trie                         │       245.06us │      42.74kw │        19.61w │        19.61w │      0.02% │
│ lookup keys list trie                         │       200.56us │      42.74kw │        18.34w │        18.34w │      0.02% │
│ find_approximate ~max_differences:0 trie      │       269.49us │      85.51kw │       531.27w │       531.27w │      0.02% │
│ find_approximate ~max_differences:1 trie      │    20_494.76us │   2_446.14kw │    35_288.71w │    35_288.71w │      1.55% │
│ find_approximate ~max_differences:2 trie      │   233_892.42us │  39_845.03kw │   227_983.00w │   227_983.00w │     17.66% │
│ find_approximate ~max_differences:3 trie      │ 1_073_743.82us │ 237_352.98kw │   839_227.00w │   839_227.00w │     81.07% │
│ find_approximate ~max_differences:0 fast trie │       340.90us │     105.36kw │       645.79w │       645.79w │      0.03% │
│ find_approximate ~max_differences:1 fast trie │    22_532.32us │   3_228.67kw │    35_865.35w │    35_865.35w │      1.70% │
│ find_approximate ~max_differences:2 fast trie │   266_948.38us │  51_629.14kw │   230_518.00w │   230_518.00w │     20.16% │
│ find_approximate ~max_differences:3 fast trie │ 1_142_019.75us │ 285_542.86kw │   842_896.00w │   842_896.00w │     86.23% │
│ find_approximate ~max_differences:0 list trie │     1_036.10us │     331.53kw │     1_889.15w │     1_889.15w │      0.08% │
│ find_approximate ~max_differences:1 list trie │    38_308.43us │  10_671.63kw │    38_606.55w │    38_606.55w │      2.89% │
│ find_approximate ~max_differences:2 list trie │   316_325.46us │  88_330.19kw │   240_746.30w │   240_746.30w │     23.88% │
│ find_approximate ~max_differences:3 list trie │ 1_324_436.43us │ 408_636.18kw │   880_151.00w │   880_151.00w │    100.00% │
│ find_approximate ~max_differences:0 naive     │   271_495.15us │  53_951.27kw │ 3_324_284.80w │ 3_324_284.80w │     20.50% │
│ find_approximate ~max_differences:1 naive     │   248_819.13us │  53_951.27kw │ 3_325_937.80w │ 3_325_937.80w │     18.79% │
│ find_approximate ~max_differences:2 naive     │   222_008.38us │  53_951.23kw │ 3_305_334.10w │ 3_305_334.10w │     16.76% │
│ find_approximate ~max_differences:3 naive     │   221_672.88us │  53_951.18kw │ 3_316_275.80w │ 3_316_275.80w │     16.74% │
└───────────────────────────────────────────────┴────────────────┴──────────────┴───────────────┴───────────────┴────────────┘
```
