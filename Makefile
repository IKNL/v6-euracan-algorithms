PKG_NAME ?= vtg.chisq
HOST ?= harbor2.vantage6.ai
IMAGE ?= starter/${PKG_NAME}
TAG ?= dev

help:
	@echo "Usage: make [target] ..."
	@echo ""
	@echo "Targets:"
	@echo "  help       Show this help"
	@echo "  echo       Show variables"
	@echo "  chisq      Build and push chisq image"
	@echo "  survfit    Build and push survfit image"
	@echo "  summary    Build and push summary image"
	@echo "  coxph      Build and push coxph image"
	@echo "  crosstab   Build and push crosstab image"
	@echo "  build      Build PKG_NAME"
	@echo "  install    Install PKG_NAME"
	@echo "  uninstall  Uninstall PKG_NAME"
	@echo "  document   Generate R documentation"
	@echo "  docker     Build docker image"
	@echo "  docker-build  Build docker image"
	@echo "  docker-push   Push docker image to registry"
	@echo ""
	@echo "Variables:"
	@echo "  PKG_NAME   Package name"
	@echo "  HOST       Docker registry host"
	@echo "  IMAGE      Docker image name"
	@echo "  TAG        Docker image tag"
	@echo ""

echo:
	@echo "package name: ${PKG_NAME}"
	@echo "  image name: ${IMAGE}"
	@echo "         tag: ${TAG}"
	@echo ""

chisq:
	make docker PKG_NAME=vtg.chisq

survdiff:
	make docker PKG_NAME=vtg.survdiff

survfit:
	make docker PKG_NAME=vtg.survfit

summary:
	make docker PKG_NAME=vtg.summary

coxph:
	make docker PKG_NAME=vtg.coxph

crosstab:
	make docker PKG_NAME=vtg.crosstab

glm:
	make docker PKG_NAME=vtg.glm

debugger:
	make docker PKG_NAME=vtg.debugger

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

	@if test "$(TAG)" = "dev"; then \
		echo "Building development image";\
		docker build \
			-f ./docker/${PKG_NAME}.Dockerfile --no-cache --build-arg PKG_NAME=${PKG_NAME} \
			--build-arg TAG=${TAG} -t ${HOST}/${IMAGE}:${TAG} . ;\
	else \
		echo "Building production image";\
		docker build \
			-f ./docker/${PKG_NAME}.Dockerfile --no-cache --build-arg PKG_NAME=${PKG_NAME} \
			--build-arg TAG=${TAG} -t ${IMAGE}:${TAG} -t ${HOST}/${IMAGE}:${TAG} \
			-t ${HOST}/${IMAGE}:${TAG} -t ${HOST}/${IMAGE}:latest . ;\
	fi

docker-push: docker-build
	@if test "$(TAG)" = "dev"; then \
		docker push ${HOST}/${IMAGE}:${TAG};\
	else \
		docker push ${HOST}/${IMAGE}:${TAG};\
		docker push ${HOST}/${IMAGE}:latest;\
	fi
