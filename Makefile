TAG ?= dev

x-squared:
	cd ./vtg.chisq && make docker TAG=${TAG}
