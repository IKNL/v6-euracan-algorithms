rm(list = ls(all.names = TRUE))
devtools::load_all("./vtg.chisq/src")
devtools::load_all("./vtg.preprocessing")

# load("./vtg.chisq/src/data/d1.rda")
# load("./vtg.chisq/src/data/d2.rda")
# load("./vtg.chisq/src/data/d3.rda")

data <- read.csv("C:/data/euracan-db.csv", header = TRUE, sep = ";")

# Calculate the number of rows in the dataframe
n_rows <- nrow(data)

# Define the number of rows for each of the three sets
set_size <- floor(n_rows / 3)

# Split the dataframe into three sets
d1 <- data[1:set_size, ]
d2 <- data[(set_size + 1):(2 * set_size), ]
d3 <- data[(2 * set_size + 1):n_rows, ]

datasets <- list(d1, d2, d3)

# n <- 1000
# e1 <- data.frame(X = sample(1:100, n, replace = TRUE),
#                  Y = sample(1:100, n, replace = TRUE))
# e2 <- data.frame(X = sample(1:100, n+10, replace = TRUE),
#                  Y = sample(1:100, n+10, replace = TRUE))
# e3 <- data.frame(X = sample(1:100, n-20, replace = TRUE),
#                  Y = sample(1:100, n-20, replace = TRUE))
# # e1[5, 1] <- 2
# datasets <- list(e1, e2, e3)

organizations_to_include <- c(1,2,3)

#
#   Build-in Chisq test
#
# subset datasets bases on organizations_to_include
data_central <- datasets[organizations_to_include]

data <- do.call(rbind, data_central)
# data <- na.omit(rbind(d1, d2, d3)) # <- `na.omit` is build in the FL ChiSq test
col <- c("age", "combstage")
central_result <- chisq.test(na.omit(data[, col]))

#
#   Federated Chisq test
#
threshold = 5L
probs = NULL

client <- vtg::MockClient$new(
  datasets = datasets,
  pkgname = 'vtg.chisq'
)


log <- lgr::get_logger("vtg/MockClient")$set_threshold("debug")
log <- lgr::get_logger("vtg/Client")$set_threshold("debug")
federated_result <- vtg.chisq::dchisq(
  client = client, col = col,
  probabilities = probs,
  organizations_to_include = organizations_to_include,
#   subset_rules = data.frame(subset = c("age>30 & age<=70"))
  subset_rules = data.frame(subset = c("combstage==988"))
)

if (is.null(federated_result$error)) {
  #
  #   Compare results
  #
  federated_result$statistic == central_result$statistic
  federated_result$parameter == central_result$parameter
  federated_result$pval == central_result$p.value

  print(federated_result$statistic)
  print(central_result$statistic)

  print(federated_result$parameter)
  print(central_result$parameter)

  print(federated_result$pval)
  print(central_result$p.value)

} else {
  print(federated_result$error)
  print(federated_result$errors)
}
