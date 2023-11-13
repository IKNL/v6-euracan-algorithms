TAG ?= dev

x-squared:
	cd ./chisq && make docker TAG=${TAG}
