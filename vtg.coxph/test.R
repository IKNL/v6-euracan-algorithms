rm(list = ls(all.names = T))
devtools::load_all("./vtg.coxph/src")
devtools::load_all("./vtg.preprocessing")

library(dplyr)
library(survival)
# Data <- read.table("https://stats.idre.ucla.edu/stat/r/examples/asa/hmohiv.csv"
# , sep=",", header = TRUE)

data1 <- read.csv("//mnt//c//data//euracan-node-a.csv")
data2 <- read.csv("//mnt//c//data//euracan-node-b.csv")
datasets <- list(data1, data2)
Data <- rbind(data1, data2)

data_local <- rbind(
  vtg.preprocessing::extend_data(data1),
  vtg.preprocessing::extend_data(data2)
)
data_local <- rbind(
  data1, data2
)

df <- data_local
df <- na.omit(df[, c("BMI", "b07_smoke", "deadOS", "surv")])

data_local[["b07_smoke"]] <- factor(data_local[["b07_smoke"]], levels = c(1, 2, 3))
regfit <- coxph(Surv(surv, deadOS) ~ b07_smoke + BMI,
  data = data_local,
  ties = "breslow"
)

time <- "surv"
event <- "deadOS"

# path <- "src/data/"

# for (i in dir(path)) load(file = paste0(path,i))

# datasets <- list(vtg.coxph::D1,vtg.coxph::D2,vtg.coxph::D3)

expl_vars <- c("b07_smoke", "BMI")
time_col <- c("surv")
censor_col <- c("deadOS")
# ties <- "breslow"
types <- list(
  # BMI = list(type = "numeric"),
  # b02_edu = list(type = "factor", levels = c(1, 999)),
  # deadOS = list(type = "factor", levels = c(0, 1)),
  b07_smoke = list(type = "factor", levels = c(1, 2, 3))
)

# First... #
print(".............. FEDERATED ANALSYIS ..............")
client <- vtg::MockClient$new(datasets, pkgname = "vtg.coxph")
fit <- vtg.coxph::dcoxph(client, expl_vars, time_col, censor_col,
  types = types, organizations_to_include = NULL, extend_data = FALSE
)
