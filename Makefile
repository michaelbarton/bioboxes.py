path    := PATH=.tox/py27/bin:$(shell echo "${PATH}")
version := $(shell $(path) python setup.py --version)
name    := $(shell $(path) python setup.py --name)
dist    := ./.tox/dist/$(name)-$(version).zip

NO_COLOR=\x1b[0m
OK_COLOR=\x1b[32;01m
ERROR_COLOR=\x1b[31;01m
WARN_COLOR=\x1b[33;01m

#################################################
#
# Publish the pip package
#
#################################################

publish: $(dist)
	@$(path) twine upload \
		--username ${PYPI_USERNAME} \
		--password ${PYPI_PASSWORD} \
		$^

build: $(dist)

$(dist): $(shell find biobox) requirements/default.txt setup.py MANIFEST.in
	tox -e py27 --sdistonly
	touch $@

#################################################
#
# Unit tests
#
#################################################

test     = tox -- $(ARGS)
autotest = clear && $(test) -m \'not slow\'
wip      = clear && $(test) -m \'wip\'
wip-found = $(shell find test -name '*.py' | xargs grep '@pytest.mark.wip')

# "Work in Progress" unit tests
# Useful for testing only the code currently being developed
# Should not however be checked into version control
wip: tmp/tests
	@$(wip)

test: tmp/tests
	@if test -n "$(wip-found)"; then\
		echo "$(ERROR_COLOR)Work in progress tests found: '@pytest.mark.wip'. Please remove first.$(NO_COLOR)\n"; \
		exit 1; \
	fi
	@$(test)

autotest: tmp/tests
	@$(autotest) || true # Using true starts tests even on failure
	@fswatch \
		--exclude 'pyc' \
		--one-per-batch	./biobox \
		--one-per-batch ./test \
		| xargs -n 1 -I {} bash -c "$(autotest)"

#################################################
#
# Bootstrap project requirements for development
#
#################################################

bootstrap: \
	tmp/data/reads.fq.gz \
	tmp/data/contigs.fa \
	tmp/reference/reference.fa
	mkdir -p ./tmp/tests
	docker pull bioboxes/tadpole@sha256:d20cdfc02f9e305c931a93c34a8678791d2ebc084f257afd57a79f772e0b470d
	docker pull bioboxes/quast@sha256:1dfe1fb0eb84cd7344b6821cd4f4cdb3f5c1ccb330438eea640b4ce6fda1c4bb
	docker pull alpine:3.3
	docker pull alpine@sha256:9cacb71397b640eca97488cf08582ae4e4068513101088e9f96c9814bfda95e0

tmp/reference/reference.fa: tmp/data/reference.fa
	@mkdir -p $(dir $@)
	@mv $< $@

tmp/data/%:
	@mkdir -p $(dir $@)
	@wget \
		--quiet \
		--output-document $@ \
		https://s3-us-west-1.amazonaws.com/nucleotides-testing/short-read-assembler/$*

tmp/tests:
	mkdir -p $@

.PHONY: bootstrap build test test-build autotest wip publish
