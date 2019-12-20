
GH_USERNAME=dduportal
PROJECT_NAME=ensg-ci-cd

ifdef TRAVIS_TAG
PRESENTATION_URL ?= https://$(GH_USERNAME).github.io/$(PROJECT_NAME)/$(TRAVIS_TAG)
else
	ifneq ($(TRAVIS_BRANCH), master)
	PRESENTATION_URL ?= https://$(GH_USERNAME).github.io/$(PROJECT_NAME)/$(TRAVIS_BRANCH)
	else
	PRESENTATION_URL ?= https://$(GH_USERNAME).github.io/$(PROJECT_NAME)
	endif
endif
export PRESENTATION_URL

all: clean build verify

# Generate documents inside a container, all *.adoc in parallel
build: clean
	@docker-compose up \
		--build \
		--force-recreate \
		--exit-code-from build \
	build

verify: verify-links

verify-links:
	@docker run --rm \
		-v $(CURDIR)/dist:/dist \
		18fgsa/html-proofer \
			--check-html \
			--url-ignore "/localhost:/,/127.0.0.1:/,/$(PRESENTATION_URL)/" \
        	/dist/index.html

serve: clean
	@docker-compose up --build --force-recreate serve

shell:
	@docker-compose up --build --force-recreate -d serve
	@docker-compose exec serve sh

deploy:
	@bash $(CURDIR)/scripts/travis-gh-deploy.sh

clean: chmod
	@docker-compose down -v --remove-orphans
	rm -rf $(CURDIR)/dist $(CURDIR)/docs

qrcode:
	@docker-compose up --build --force-recreate qrcode

chmod:
	@docker run --rm -t -v $(CURDIR):/app \
		alpine chown -R "$$(id -u):$$(id -g)" /app

.PHONY: all build verify verify-links serve deploy qrcode chmod
