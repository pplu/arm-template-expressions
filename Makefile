test:
	carton exec prove -I lib t/

pull-examples:
	git submodule init
	git submodule update
