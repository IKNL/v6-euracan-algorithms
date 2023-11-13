PKG_NAME ?= vtg.chisq
DIR ?= $(shell pwd)/${PKG_NAME}
HOST ?= harbor2.vantage6.ai
IMAGE ?= starter/${PKG_NAME}
TAG ?= dev

echo:
	@echo "package name: ${PKG_NAME}"
	@echo "  image name: ${IMAGE}"
	@echo "         tag: ${TAG}"
	@echo ""

vtg.chisq:
	make docker IMAGE=starter/vtg.chisq

build: install-deps document
	@echo "*** Building \"$(PKG_NAME)\" ***"
	@mkdir ../dist; cd ../dist; R CMD build ../src

install-deps: DESCRIPTION
	@echo "*** Installing dependencies for \"$(PKG_NAME)\" ***"
	@Rscript -e 'library(devtools)' -e 'install_deps(".")'

install: install-deps document
	@echo "*** Installing package \"$(PKG_NAME)\" ***"
	@R CMD INSTALL --no-multiarch --with-keep.source .

uninstall:
	@echo "*** Removing package \"$(PKG_NAME)\" ***"
	@R CMD REMOVE ${PKG_NAME}

DESCRIPTION:
	@echo "Generating \"DESCRIPTION\" from \"DESCRIPTION.tpl\""
	@echo "vantage6-Comment:" > DESCRIPTION
	@echo "    **************************************************" >> DESCRIPTION
	@echo "    * This file was generated from DESCRIPTION.tpl   *" >> DESCRIPTION
	@echo "    * Please don't modify it directly! Instead,      *" >> DESCRIPTION
	@echo "    * modify DESCRIPTION.tpl and run the following   *" >> DESCRIPTION
	@echo "    * command:                                       *" >> DESCRIPTION
	@echo "    *   make DESCRIPTION                             *" >> DESCRIPTION
	@echo "    **************************************************" >> DESCRIPTION
	@sed "s/{{PKG_NAME}}/${PKG_NAME}/g" ./src/DESCRIPTION.tpl >> ./src/DESCRIPTION

document:
	@Rscript -e "devtools::document(roclets=c('rd', 'collate', 'namespace', 'vignette'))"

docker: DESCRIPTION docker-build docker-push

docker-build:
	@echo "************************************************************************"
	@echo "* Building image '${IMAGE}:${TAG}' "
	@echo "************************************************************************"

	docker build \
	  -f ./docker/${PKG_NAME}.Dockerfile \
	   --build-arg PKG_NAME=${PKG_NAME} \
	  -t ${IMAGE}:${TAG} \
	  -t ${HOST}/${IMAGE}:${TAG} \
	  ${DIR}

docker-push: docker-build
	docker push ${HOST}/${IMAGE}:${TAG}

