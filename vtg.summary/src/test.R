rm(list = ls(all.names = TRUE))
devtools::load_all("./vtg.summary/src")
devtools::load_all("./vtg.preprocessing")

# create fake data. Three columns with random numbers, two columns with factors
set.seed(123L);
columns = c("A", "B", "C", "D", "E")
data <- data.frame("A" = sample(1:10, size = 1000, replace = TRUE),
                   "B" = sample(c(1:3, NA), size= 1000, replace = TRUE),
                   "C" = sample(c(6:19, NA), size= 1000, replace = TRUE),
                   "D" = sample(gl(10, 100), size = 1000, replace = TRUE),
                   "E" = sample(factor(as.character(c("female", "male", NA))),
                                size = 1000, replace = TRUE))

# Split the dataframe into two sets
n_rows <- nrow(data)
set_size <- floor(n_rows / 2)

d1 <- data[1:set_size, ]
d2 <- data[(set_size + 1):n_rows, ]
datasets <- list(d1, d2)

# create client
client <- vtg::MockClient$new(
  datasets = datasets,
  pkgname = "vtg.summary"
)

# define organizations
organizations_to_include <- c(1, 2)

log <- lgr::get_logger("vtg/MockClient")$set_threshold("debug")
log <- lgr::get_logger("vtg/Client")$set_threshold("debug")

threshold = 5L
types=NULL

federated_result <- vtg.summary::dsummary(
  client=client,
  columns=columns,
  threshold=threshold,
  types=types,
  organizations_to_include=organizations_to_include,
  is_extend_data=FALSE
)

print("federated result")
print(federated_result)

# check values
stopifnot("nan_count" %in% names(federated_result))
stopifnot(federated_result$mean[1] == 5.698)
stopifnot(abs(federated_result$mean[2] == 2.009259) < 0.0001)
stopifnot(abs(federated_result$mean[3] == 12.590022) < 0.0001)
stopifnot(abs(federated_result$variance[1] - 8.2150110) < 0.0001)
stopifnot(federated_result$nan_count[1] == 0)
stopifnot(federated_result$nan_count[2] == 244)
stopifnot(federated_result$nan_count[3] == 78)
stopifnot(federated_result$nan_count[4] == 0)
stopifnot(federated_result$nan_count[1] + federated_result$length[1] == 1000)
stopifnot(federated_result$nan_count[2] + federated_result$length[2] == 1000)
stopifnot(federated_result$nan_count[3] + federated_result$length[3] == 1000)
stopifnot(federated_result$nan_count[4] + federated_result$length[4] == 1000)
stopifnot(federated_result$complete_rows == 479)
awef

# try to run with a single numeric column
columns=c("A")
federated_result <- vtg.summary::dsummary(
  client,
  columns,
  threshold=threshold,
  types=types,
  organizations_to_include=organizations_to_include,
  is_extend_data=FALSE
)
print(federated_result)
stopifnot(federated_result$mean[1] == 5.698)
stopifnot(federated_result$nan_count[1] == 0)
stopifnot(federated_result$nan_count[1] + federated_result$length[1] == 1000)
stopifnot(federated_result$complete_rows == 1000)

# try to run with a single factorial column
columns=c("E")
federated_result <- vtg.summary::dsummary(
  client,
  columns,
  threshold=threshold,
  types=types,
  organizations_to_include=organizations_to_include,
  is_extend_data=FALSE
)
print(federated_result)
stopifnot(!("error" %in% names(federated_result)))
stopifnot(federated_result$mean[1] == NULL)
stopifnot(federated_result$nan_count[1] == 327)
stopifnot(federated_result$nan_count[1] + federated_result$length[1] == 1000)
stopifnot(federated_result$complete_rows == 673)

# check that subsetting works
columns=c("A")
federated_result <- vtg.summary::dsummary(
  client=client,
  columns=columns,
  threshold=threshold,
  types=types,
  organizations_to_include=organizations_to_include,
  is_extend_data=FALSE,
  subset_rules = data.frame(subset = c("A > 5"))
)
stopifnot(federated_result$length[1] == 534)

# set different threshold that should fail
threshold = 500L
columns = c("A", "B", "C", "D", "E")
federated_result <- vtg.summary::dsummary(
  client,
  columns,
  threshold=threshold,
  types=types,
  organizations_to_include=organizations_to_include,
  is_extend_data=FALSE
)
print("federated result")
print(federated_result)
stopifnot("error" %in% names(federated_result))
stopifnot(startsWith(federated_result$error,
                     "Disclosure risk, not enough observations in columns"))


# And yet another threshold, which should give a different error
threshold = 100L
federated_result <- vtg.summary::dsummary(
  client,
  columns,
  threshold=threshold,
  types=types,
  organizations_to_include=organizations_to_include,
  is_extend_data=FALSE
)
print("federated result")
print(federated_result)
stopifnot("error" %in% names(federated_result))
stopifnot(startsWith(
  federated_result$error,
  "Disclosure risk, not enough observations in some categories of factorial"
))

# Check if wrong column gives error
columns = c("non-existing")
threshold = 5L
federated_result <- vtg.summary::dsummary(
  client,
  columns,
  threshold=threshold,
  types=types,
  organizations_to_include=organizations_to_include,
  is_extend_data=FALSE
)
print("federated result")
print(federated_result)
stopifnot("error" %in% names(federated_result))
stopifnot(federated_result$error == "Not all columns are present in the data")



print("all tests succeeded")