rm(list = ls(all.names = TRUE))
devtools::load_all("./vtg.summary/src")
devtools::load_all("./vtg.preprocessing")

# data <- read.csv("C:/Users/bbe2101.54580/data/vantage6/starter/DB.csv", header = TRUE, sep = ";")
# print("data loaded")

# create fake data
set.seed(123L);
data <- data.frame("X" = sample(1:10, size = 1000, replace = T),
                   "Y" = sample(c(1:3, NA), size= 1000, replace = T),
                   "Z" = sample(c(6:19, NA), size= 1000, replace = T),
                   "T" = sample(gl(10, 100), size = 1000, replace = T))

# Split the dataframe into two sets
n_rows <- nrow(data)
set_size <- floor(n_rows / 2)

d1 <- data[1:set_size, ]
d2 <- data[(set_size + 1):n_rows, ]
datasets <- list(d1, d2)

# create client
client <- vtg::MockClient$new(
  datasets = datasets,
  pkgname = 'vtg.summary'
)

# define organizations
organizations_to_include <- c(1,2)

log <- lgr::get_logger("vtg/MockClient")$set_threshold("debug")
log <- lgr::get_logger("vtg/Client")$set_threshold("debug")

columns = c("X", "Y", "Z", "T")
threshold = 5L
types=NULL

federated_result <- vtg.summary::dsummary(
  client,
  columns,
  threshold=threshold,
  types=types,
  # organizations_to_include=organizations_to_include,
)


print(federated_result)
# check values
stopifnot(federated_result$global.useable.rows == 695)
stopifnot(federated_result$global.means[1] == 5.698)
stopifnot(abs(federated_result$global.means[2] == 2.009259) < 0.0001)
stopifnot(abs(federated_result$global.means[3] == 12.590022) < 0.0001)
stopifnot(abs(federated_result$global.variance[1] - 8.2150110) < 0.0001)
stopifnot(federated_result$global.nas[1] == 0)
stopifnot(federated_result$global.nas[2] == 244)
stopifnot(federated_result$global.nas[3] == 78)
stopifnot(federated_result$global.nas[4] == 0)
# stopifnot(abs(federate_result$nod))

print("all tests succeeded")