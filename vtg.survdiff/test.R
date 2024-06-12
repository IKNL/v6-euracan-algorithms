remove(list=ls(all.names = T))
# devtools::load_all("./vtg.preprocessing/src")
devtools::load_all("./vtg.survdiff/src")
library(vtg);library(survival);library(vtg.survdiff);

d1 <- read.csv("/mnt/c/data/euracan-node-a.csv")
datasets <- list(d1, d1, d1)
f <- Surv(surv, deadOS) ~ b04_sex

tmax <- 430

# Data[Data[,"futime"]>tmax ,"fustat"]=0
# Data[Data[,"futime"]>tmax ,"futime"]=tmax
# R=survdiff(f, Data)

client <- vtg::MockClient$new(datasets, pkgname = "vtg.survdiff")
fit <- vtg.survdiff::dsurvdiff(client,
                               formula = f,
                               tmax=tmax,
                               timepoints = NULL)
