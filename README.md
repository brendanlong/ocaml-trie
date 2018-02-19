[![CircleCI](https://circleci.com/gh/brendanlong/ocaml-trie.svg?style=shield)](https://circleci.com/gh/brendanlong/ocaml-trie)
[![Coverage Status](https://coveralls.io/repos/github/brendanlong/ocaml-trie/badge.svg?branch=master)](https://coveralls.io/github/brendanlong/ocaml-trie?branch=master)

This is forked from <https://www.lri.fr/~filliatr/software.en.html> for approximate string matching.

Current benchmarks:

```
┌────────────────────────────────────────────────┬──────────────┬──────────────┬───────────────┬───────────────┬────────────┐
│ Name                                           │     Time/Run │      mWd/Run │      mjWd/Run │      Prom/Run │ Percentage │
├────────────────────────────────────────────────┼──────────────┼──────────────┼───────────────┼───────────────┼────────────┤
│ populate map                                   │     709.08us │      86.39kw │     1_719.23w │     1_719.23w │      0.08% │
│ populate hash table                            │     182.35us │      10.69kw │     7_501.45w │     6_476.45w │      0.02% │
│ populate trie                                  │     642.07us │     114.69kw │    10_118.66w │    10_118.66w │      0.08% │
│ populate array trie                            │   3_261.10us │     471.52kw │    28_113.42w │    28_113.42w │      0.38% │
│ lookup keys map                                │     322.66us │       5.00kw │        50.41w │        50.41w │      0.04% │
│ lookup keys hash table                         │      55.18us │       5.00kw │        48.33w │        48.33w │            │
│ lookup keys trie                               │     153.99us │      23.02kw │        18.87w │        18.87w │      0.02% │
│ lookup keys array trie                         │     147.99us │      33.58kw │        18.46w │        18.46w │      0.02% │
│ find_approximate ~max_differences:0 trie       │     213.97us │      32.02kw │       215.90w │       215.90w │      0.03% │
│ find_approximate ~max_differences:1 trie       │  20_691.63us │     916.04kw │    30_535.55w │    30_535.55w │      2.44% │
│ find_approximate ~max_differences:2 trie       │ 233_839.29us │  16_766.60kw │   213_162.90w │   213_162.90w │     27.59% │
│ find_approximate ~max_differences:3 trie       │ 847_407.53us │ 122_534.26kw │   821_770.00w │   821_770.00w │    100.00% │
│ find_approximate ~max_differences:0 array trie │     206.26us │      42.58kw │       281.79w │       281.79w │      0.02% │
│ find_approximate ~max_differences:1 array trie │  19_392.88us │   1_928.79kw │    33_032.44w │    33_032.44w │      2.29% │
│ find_approximate ~max_differences:2 array trie │ 210_971.73us │  20_073.43kw │   212_757.40w │   212_757.40w │     24.90% │
│ find_approximate ~max_differences:3 array trie │ 840_106.39us │ 143_431.08kw │   833_008.50w │   833_008.50w │     99.14% │
│ find_approximate ~max_differences:0 naive      │ 277_164.32us │  54_473.31kw │ 3_308_691.90w │ 3_308_691.90w │     32.71% │
│ find_approximate ~max_differences:1 naive      │ 264_931.17us │  54_473.36kw │ 3_310_640.60w │ 3_310_640.60w │     31.26% │
│ find_approximate ~max_differences:2 naive      │ 369_660.00us │  54_473.29kw │ 3_308_716.00w │ 3_308_716.00w │     43.62% │
│ find_approximate ~max_differences:3 naive      │ 306_107.95us │  54_473.27kw │ 3_298_117.50w │ 3_298_117.50w │     36.12% │
└────────────────────────────────────────────────┴──────────────┴──────────────┴───────────────┴───────────────┴────────────┘
```

 - `trie` is using `Trie.Make(Map.Make(Char))`
 - `array trie` is using a sorted-array map for the nodes (much slower to setup, faster due to better cache usage)
 - `naive` is just looping through every word and checking the levenshtein distance
