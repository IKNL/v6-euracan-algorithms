devtools::load_all("./vtg.coxph/src")

data("cancer")

# status needs to be 0 or 1 in our case
cancer$status <- cancer$status - 1

# divide the data into two parts, party one 33% and party two 67%
n_a <- ceiling(nrow(cancer) * 0.33)
n_b <- nrow(cancer) - n_a

party_a <- cancer[1:n_a, ]
party_b <- cancer[(n_a + 1):nrow(cancer), ]

# # initialize mock client
client <- vtg::MockClient$new(
  datasets = list(cancer),
  pkgname = "vtg.coxph"
)

types <- list(
  # age = list(type = "numeric"),
  # time = list(type = "numeric"),
  sex = list(type = "factor", levels = c(1, 2))
  # status = list(type = "factor", levels = c(1, 2))
)

df <- cancer
# df[["sex"]] <- factor(df[["sex"]], levels = c(1, 2))
# df <- one_hot_encoding(df, "sex")$data
central <- coxph(Surv(time, status) ~ sex, data = df, ties = "breslow")

federated <- vtg.coxph::dcoxph(
  client = client, expl_vars = "sex",
  time_col = "time", censor_col = "status",
  organizations_to_include = NULL, subset_rules = NULL,
  types = types, extend_data = FALSE
)
print(federated)
print(central)
