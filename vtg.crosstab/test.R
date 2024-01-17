rm(list = ls(all.names = TRUE))
devtools::load_all("./src")
devtools::load_all("../vtg.preprocessing")
library(vtg.crosstab)

data1 <- read.csv("/mnt/c/data/euracan-node-a.csv")
data2 <- read.csv("/mnt/c/data/euracan-node-b.csv")
data2 <- data2[data2$e34_cstage != 5, ]

# change the first row and make b04_sex collumn 999
data2$b04_sex[1] <- 999

dataset <- list(data1, data2)

# Data = rbind(data1, data2)

data_local <- rbind(vtg.preprocessing::extend_data(data1),
                    vtg.preprocessing::extend_data(data2))

# dataset = rbind(data1, data2)

formula = as.formula(~ e34_cstage + b04_sex)

crosstab.mock <- function(dataset,formula){
    client=vtg::MockClient$new(datasets = dataset,pkgname = 'vtg.crosstab')
    result=vtg.crosstab::dct(client = client, f = formula,
                             organizations_to_include = NULL)
    return(result)
}

res <- crosstab.mock(dataset = dataset, formula = formula)
# compare to... works!
xtabs(formula,data)
