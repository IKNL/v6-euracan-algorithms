Validation
==========
We have validated the ``dcoxph`` against the R ``coxph`` function from the ``survival``
package. The results are consistent with the R package.

We used the ``cancer`` dataset from the ``survival`` package. The dataset contains
information about 228 patients with advanced lung cancer. The dataset contains the
following columns:

- ``time``: survival time in days
- ``status``: censoring status (0=censored, 1=event)
- ``age``: age of the patient

We used the ``time`` and ``status`` columns as the response variable and the ``age``
column as the predictor variable. We fitted the Cox proportional hazards model using
the ``cancer`` dataset and compared the results with the R package.

.. code-block:: r
  :caption: Creating datasets
  library(survival)
  data("cancer")

  # status needs to be 0 or 1 for the coxph, data contains 1 or 2
  cancer$status <- cancer$status - 1

  # divide the data into two parts, party one 33% and party two 67%
  n_a <- ceiling(nrow(cancer) * 0.33)
  n_b <- nrow(cancer) - n_a

  party_a <- cancer[1:n_a, ]
  party_b <- cancer[(n_a + 1):nrow(cancer), ]

Then we can execute the centralized analysis:

.. code-block:: r
  :caption: Centralized analysis

  central <- coxph(Surv(time, status) ~ sex, data = cancer, ties = "breslow")
  # Call:
  # coxph(formula = Surv(time, status) ~ sex, data = cancer, ties = "breslow")
  #
  #        coef exp(coef) se(coef)      z       p
  # sex -0.5304    0.5884   0.1672 -3.173 0.00151
  #
  # Likelihood ratio test=10.61  on 1 df, p=0.001126
  # n= 228, number of events= 165

And the same for the federated analaysis:

.. code-block:: r
  :caption: Federated Analysis

  # initialize mock client
  client <- vtg::MockClient$new(datasets = list(cancer),
                                pkgname = "vtg.coxph")

  federated <- vtg.coxph::dcoxph(client = client, expl_vars = "sex",
                                time_col = "time", censor_col = "status",
                                organizations_to_include = NULL, subset_rules = NULL,
                                types = NULL, extend_data = FALSE)

  print(federated)
  #         coef exp.coef.      SE lower_ci upper_ci     Z     P     var
  # sex -0.5304   0.58837 0.16718  0.42398   0.8165 -3.17 0.002 0.02795


