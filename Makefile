test:
	carton exec prove -I lib t/

pull-examples:
	git submodule init
	git submodule update

gen-classes:
	rm -rf auto-lib
	carton exec perl -I build-lib/ build-bin/build-models
