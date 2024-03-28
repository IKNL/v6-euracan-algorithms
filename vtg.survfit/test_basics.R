devtools::load_all("./vtg.survfit/src")
library(survival)
data("cancer")

# status needs to be 0 or 1 in our case
cancer$status <- cancer$status - 1

# divide the data into two parts, party one 33% and party two 67%
n_a <- ceiling(nrow(cancer) * 0.33)
n_b <- nrow(cancer) - n_a

party_a <- cancer[1:n_a, ]
party_b <- cancer[(n_a + 1):nrow(cancer), ]

# # initialize mock client
client <- vtg::MockClient$new(datasets = list(party_a, party_b),
                              pkgname = "vtg.survfit")

federated <- vtg.survfit::dsurvfit(client = client,
                         formula = Surv(time, status) ~ age,
                         organizations_to_include = NULL, subset_rules = NULL,
                         extend_data = FALSE)

central <- survfit(Surv(time, status) ~ age, data = cancer)
# plot(central, main = "Central Model", xlab = "Time", ylab = "Survival Probability")

print(federated)
print(central)