dist: readme
	cpanm -l dzil-local -n Dist::Zilla
	PATH=$(PATH):dzil-local/bin PERL5LIB=dzil-local/lib/perl5 dzil authordeps --missing | cpanm -n -l dzil-local/
	PATH=$(PATH):dzil-local/bin PERL5LIB=dzil-local/lib/perl5 dzil build

readme:
	cpanm -l dzil-local -n Pod::Markdown
	PATH=$(PATH):dzil-local/bin PERL5LIB=dzil-local/lib/perl5 pod2markdown lib/AzureARM.pm > README.md

test:
	carton exec prove -I lib t/

pull-examples:
	git submodule init
	git submodule update

gen-classes:
	rm -rf auto-lib
	carton exec perl -I build-lib/ build-bin/build-models
