devtools::load_all("./vtg.preprocessing/R")
devtools::load_all("./vtg.crosstab/src")
library(pivottabler)

data("esoph")

f <- as.formula(~ agegp + alcgp + tobgp)

# divide the data into two parts, party one 33% and party two 67%
n_a <- ceiling(nrow(esoph) * 0.33)
n_b <- nrow(esoph) - n_a

party_a <- esoph[1:n_a, ]
party_b <- esoph[(n_a + 1):nrow(esoph), ]

# initialize mock client
client <- vtg::MockClient$new(datasets = list(party_a, party_b),
                              pkgname = "vtg.crosstab")

federated_raw <- vtg.crosstab::dct(client = client, f = f,
                               organizations_to_include = NULL, extent_data = FALSE)

federated <- qpvt(federated_raw, c("tobgp", "agegp"), "alcgp", "Freq[n()]", totals = c())

# Add row and column labels
# rownames(federated) <- paste("Row Label", rownames(federated))
# colnames(federated) <- paste("Column Label", colnames(federated))

centralized <- xtabs(formula = f, data = esoph)