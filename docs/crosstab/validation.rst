Validation
==========

We have validated the `dct` against the R `xtabs` function. The outputs
are identical.

.. code-block:: r
  :caption: Federated and Centralized Crosstab execution

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

  federated <- qpvt(federated_raw, c("agegp", "tobgp"), "alcgp", "Freq[n()]", totals = c())

  centralized <- xtabs(formula = f, data = esoph)

.. code-block:: r
  :caption: Centralized results

  print(centralized)
  # , , tobgp = 0-9g/day
  #
  #        alcgp
  # agegp   0-39g/day 40-79 80-119 120+
  #   25-34         1     1      1    1
  #   35-44         1     1      1    1
  #   45-54         1     1      1    1
  #   55-64         1     1      1    1
  #   65-74         1     1      1    1
  #   75+           1     1      1    1
  #
  # , , tobgp = 10-19
  #
  #        alcgp
  # agegp   0-39g/day 40-79 80-119 120+
  #   25-34         1     1      1    1
  #   35-44         1     1      1    1
  #   45-54         1     1      1    1
  #   55-64         1     1      1    1
  #   65-74         1     1      1    1
  #   75+           1     1      1    1
  #
  # , , tobgp = 20-29
  #
  #        alcgp
  # agegp   0-39g/day 40-79 80-119 120+
  #   25-34         1     1      0    1
  #   35-44         1     1      1    1
  #   45-54         1     1      1    1
  #   55-64         1     1      1    1
  #   65-74         1     1      1    1
  #   75+           0     1      0    0
  #
  # , , tobgp = 30+
  #
  #        alcgp
  # agegp   0-39g/day 40-79 80-119 120+
  #   25-34         1     1      1    1
  #   35-44         1     1      1    0
  #   45-54         1     1      1    1
  #   55-64         1     1      1    1
  #   65-74         1     0      1    1
  #   75+           1     1      0    0

.. code-block:: r
  :caption: Federated results

  print(federated)
  #                  0-39g/day  40-79  80-119  120+
  # 0-9g/day  25-34          1      1       1     1
  #           35-44          1      1       1     1
  #           45-54          1      1       1     1
  #           55-64          1      1       1     1
  #           65-74          1      1       1     1
  #           75+            1      1       1     1
  # 10-19     25-34          1      1       1     1
  #           35-44          1      1       1     1
  #           45-54          1      1       1     1
  #           55-64          1      1       1     1
  #           65-74          1      1       1     1
  #           75+            1      1       1     1
  # 20-29     25-34          1      1       0     1
  #           35-44          1      1       1     1
  #           45-54          1      1       1     1
  #           55-64          1      1       1     1
  #           65-74          1      1       1     1
  #           75+            0      1       0     0
  # 30+       25-34          1      1       1     1
  #           35-44          1      1       1     0
  #           45-54          1      1       1     1
  #           55-64          1      1       1     1
  #           65-74          1      0       1     1
  #           75+            1      1       0     0
