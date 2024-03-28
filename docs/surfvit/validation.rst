Validation
==========
We have validated the ``dsurvfit`` against the R ``survfit`` function from the
``survival`` package. The results are consistent with the R package.

We used the ``cancer`` dataset from the ``survival`` package. The dataset contains
information about 228 patients with advanced lung cancer. The dataset contains the
following columns:

- ``time``: survival time in days
- ``status``: patient status (dead or alive)
- ``age``: age of the patient

We used the ``time`` and ``status`` columns as the response variable and the ``age``
column as the predictor variable. We fitted the kaplan-meier curve using the ``cancer``
dataset and compared the results with the R package.

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

  central <- survfit(Surv(time, status) ~ age, data = cancer)
  print(central)
  #           n events median 0.95LCL 0.95UCL
  # age=39  2      0     NA      NA      NA
  # age=40  1      1    132      NA      NA
  # age=41  1      0     NA      NA      NA
  # age=42  1      0     NA      NA      NA
  # age=43  1      0     NA      NA      NA
  # age=44  5      3    268     181      NA
  # age=45  1      0     NA      NA      NA
  # age=46  1      1    320      NA      NA
  # age=47  1      1    353      NA      NA
  # age=48  4      3    419     223      NA
  # age=49  2      2    146      81      NA
  # age=50  6      5    239     131      NA
  # age=51  2      1    705      NA      NA
  # age=52  2      1     81      81      NA
  # age=53  9      7    226     202      NA
  # age=54  4      3    490     163      NA
  # age=55  6      4    308     156      NA
  # age=56  9      7    363     197      NA
  # age=57  9      6    245     170      NA
  # age=58  8      5    371     348      NA
  # age=59  8      6    433     293      NA
  # age=60 11      8    199     145      NA
  # age=61  5      4    166     147      NA
  # age=62  7      5    291     105      NA
  # age=63 11      7    519     189      NA
  # age=64 11      6    477     110      NA
  # age=65  8      6    174      60      NA
  # age=66  7      5    288     156      NA
  # age=67  8      6    230     208      NA
  # age=68 10      9    455     310      NA
  # age=69 11      7    450     329      NA
  # age=70 10      8    460     229      NA
  # age=71  7      6    332     284      NA
  # age=72  7      7    270      54      NA
  # age=73  6      6    164      59      NA
  # age=74 10      6    306      93      NA
  # age=75  5      4    396     201      NA
  # age=76  5      5    116      95      NA
  # age=77  2      0     NA      NA      NA
  # age=80  2      2    323     283      NA
  # age=81  1      1     11      NA      NA
  # age=82  1      1     31      NA      NA

And the same for the federated analaysis:

.. code-block:: r
  :caption: Federated Analysis

  # initialize mock client
  client <- vtg::MockClient$new(datasets = list(party_a, party_b),
                              pkgname = "vtg.survfit")

  federated <- vtg.survfit::dsurvfit(client = client,
                          formula = Surv(time, status) ~ age,
                          organizations_to_include = NULL, subset_rules = NULL,
                          extend_data = FALSE)
  print(federated)
  #          n  events median 0.95LCL 0.95UCL
  # age=39 2  0      NA     NA      NA
  # age=40 1  1      132    NA      NA
  # age=41 1  0      NA     NA      NA
  # age=42 1  0      NA     NA      NA
  # age=43 1  0      NA     NA      NA
  # age=44 5  3      268    181     NA
  # age=45 1  0      NA     NA      NA
  # age=46 1  1      320    NA      NA
  # age=47 1  1      353    NA      NA
  # age=48 4  3      305    223     NA
  # age=49 2  2      81     81      NA
  # age=50 6  5      239    131     NA
  # age=51 2  1      705    NA      NA
  # age=52 2  1      81     81      NA
  # age=53 9  7      226    202     NA
  # age=54 4  3      457    163     NA
  # age=55 6  4      186    156     NA
  # age=56 9  7      363    197     NA
  # age=57 9  6      245    170     NA
  # age=58 8  5      371    348     NA
  # age=59 8  6      433    293     NA
  # age=60 11 8      199    145     NA
  # age=61 5  4      166    147     NA
  # age=62 7  5      291    105     NA
  # age=63 11 7      519    189     NA
  # age=64 11 6      477    110     NA
  # age=65 8  6      62     60      NA
  # age=66 7  5      288    156     NA
  # age=67 8  6      230    208     NA
  # age=68 10 9      455    310     NA
  # age=69 11 7      450    329     NA
  # age=70 10 8      460    229     NA
  # age=71 7  6      310    284     NA
  # age=72 7  7      270    54      NA
  # age=73 6  6      153    59      NA
  # age=74 10 6      306    93      NA
  # age=75 5  4      351    201     NA
  # age=76 5  5      116    95      NA
  # age=77 2  0      NA     NA      NA
  # age=80 2  2      283    283     NA
  # age=81 1  1      11     NA      NA
  # age=82 1  1      31     NA      NA

