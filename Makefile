PKG_NAME ?= vtg.chisq
HOST ?= harbor2.vantage6.ai
IMAGE ?= starter/${PKG_NAME}
TAG ?= dev

echo:
	@echo "package name: ${PKG_NAME}"
	@echo "  image name: ${IMAGE}"
	@echo "         tag: ${TAG}"
	@echo ""

chisq:
	make docker PKG_NAME=vtg.chisq

summary:
	make docker PKG_NAME=vtg.summary

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
	@echo "vantage6-Comment:" > ./${PKG_NAME}/src/DESCRIPTION
	@echo "    **************************************************" >> ./${PKG_NAME}/src/DESCRIPTION
	@echo "    * This file was generated from DESCRIPTION.tpl   *" >> ./${PKG_NAME}/src/DESCRIPTION
	@echo "    * Please don't modify it directly! Instead,      *" >> ./${PKG_NAME}/src/DESCRIPTION
	@echo "    * modify DESCRIPTION.tpl and run the following   *" >> ./${PKG_NAME}/src/DESCRIPTION
	@echo "    * command:                                       *" >> ./${PKG_NAME}/src/DESCRIPTION
	@echo "    *   make DESCRIPTION                             *" >> ./${PKG_NAME}/src/DESCRIPTION
	@echo "    **************************************************" >> ./${PKG_NAME}/src/DESCRIPTION
	@sed "s/{{PKG_NAME}}/${PKG_NAME}/g" ./${PKG_NAME}/src/DESCRIPTION.tpl >> ./${PKG_NAME}/src/DESCRIPTION

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
	  -t ${HOST}/${IMAGE}:latest \
	  .

docker-push: docker-build
	docker push ${HOST}/${IMAGE}:${TAG}
	docker push ${HOST}/${IMAGE}:latest

