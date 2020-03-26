SHELL := /bin/bash

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
		bundle install; \
	  bundle exec rake release || exit $$?; \
	  popd; \
	done
