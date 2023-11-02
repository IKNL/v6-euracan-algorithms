rm(list = ls(all.names = TRUE))
devtools::load_all("./src")

load("src/data/d1.rda")
load("src/data/d2.rda")
load("src/data/d3.rda")
datasets <- list(d1, d2, d3)
organizations_to_include <- c(1)

#
#   Build-in Chisq test
#
# subset datasets bases on organizations_to_include
data_central <- datasets[organizations_to_include]

data <- na.omit(do.call(rbind, data_central))
# data <- na.omit(rbind(d1, d2, d3)) # <- `na.omit` is build in the FL ChiSq test
col <- c("X", "Y", "Z")
central_result <- chisq.test(data)


#
#   Federated Chisq test
#
threshold = 5L
probs=NULL

client = vtg::MockClient$new(
    datasets = datasets,
    pkgname = 'vtg.chisq'
)

log <- lgr::get_logger("vtg/MockClient")$set_threshold("debug")
log <- lgr::get_logger("vtg/Client")$set_threshold("debug")

federated_result <- vtg.chisq::dchisq(
  client = client, col = col,
  threshold = threshold,
  probabilities = probs,
  organizations_to_include = organizations_to_include
)

#
#   Compare results
#
federated_result$statistic == central_result$statistic
federated_result$parameter == central_result$parameter
federated_result$pval == central_result$p.value
