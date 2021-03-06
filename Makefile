
CURRENT_UID = $(shell id -u):$(shell id -g)
DIST_DIR ?= $(CURDIR)/dist
REPOSITORY_NAME ?= ensg-ci-cd
REPOSITORY_OWNER ?= dduportal
REPOSITORY_BASE_URL ?= https://github.com/$(REPOSITORY_OWNER)/$(REPOSITORY_NAME)

### TRAVIS_BRANCH == TRAVIS_TAG when a build is triggered by a tag as per https://docs.travis-ci.com/user/environment-variables/
ifndef TRAVIS_BRANCH
# Running outside Travis
TRAVIS_BRANCH = $(shell git rev-parse --abbrev-ref HEAD)
endif

REPOSITORY_URL = $(REPOSITORY_BASE_URL)/tree/$(TRAVIS_BRANCH)
PRESENTATION_URL = https://$(REPOSITORY_OWNER).github.io/$(REPOSITORY_NAME)/$(TRAVIS_BRANCH)

export PRESENTATION_URL CURRENT_UID REPOSITORY_URL REPOSITORY_BASE_URL TRAVIS_BRANCH

all: clean build verify

# Generate documents inside a container, all *.adoc in parallel
build: clean $(DIST_DIR)
	@docker-compose up \
		--build \
		--force-recreate \
		--exit-code-from build \
	build

$(DIST_DIR):
	mkdir -p $(DIST_DIR)

verify:
	@docker run --rm \
		-v $(DIST_DIR):/dist \
		--user $(CURRENT_UID) \
		18fgsa/html-proofer \
			--check-html \
			--http-status-ignore "999" \
			--url-ignore "/localhost/,/gitserver:3000/,/jenkins:8080/,/127.0.0.1/,/$(PRESENTATION_URL)/,/github.com\/$(REPOSITORY_OWNER)\/slides\/tree/" \
        	/dist/index.html

serve: clean
	@docker-compose up --build --force-recreate serve

shell:
	@docker-compose up --build --force-recreate -d wait
	@docker-compose exec --user root wait sh

$(DIST_DIR)/index.html: build

pdf: $(DIST_DIR)/index.html
	@docker run --rm -t \
		-v $(DIST_DIR):/slides \
		--user $(CURRENT_UID) \
		--read-only=true \
		--tmpfs=/tmp \
		astefanutti/decktape:2.9 \
		/slides/index.html \
		/slides/slides.pdf \
		--size='2048x1536'

deploy:
	@bash $(CURDIR)/scripts/travis-gh-deploy.sh

clean:
	@docker-compose down -v --remove-orphans
	@rm -rf $(DIST_DIR)

qrcode:
	@docker-compose up --build --force-recreate qrcode

.PHONY: all build verify serve deploy qrcode pdf
