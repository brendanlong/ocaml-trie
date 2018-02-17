build:
	@jbuilder build @install --dev

benchmark:
	@jbuilder build bench/bench_trie.exe
	@_build/default/bench/bench_trie.exe -quota 1

clean:
	@jbuilder clean
	@rm -rf _coverage bisect*.out

coverage: clean
	@BISECT_ENABLE=YES jbuilder runtest --dev
	@bisect-ppx-report -I _build/default/ -html _coverage/ \
	  `find . -name 'bisect*.out'`

test:
	@jbuilder runtest --dev

.PHONY: benchmark build clean coverage test
