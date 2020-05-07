SHELL := /bin/bash -x

test:
	for i in peatio-*; do \
	  pushd $$i; \
	  bundle install; \
	  bundle exec rspec || exit $$?; \
	  popd; \
	done

release:
	for i in peatio-*; do \
	  pushd $$i; \
		git status; \
		rm -f *.gem; \
		bundle install; \
		gem build *.gemspec && \
		gem push *.gem; \
	  popd; \
	done
