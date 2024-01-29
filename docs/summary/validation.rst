Validation
==========

We have validated the `dsummary` against the R `summary` function. The outputs
are identical.


First lets create some example data. We will use the `set.seed` function to
ensure that the results are reproducible.

.. code-block:: r
  :caption: Example data

  # Create a data frame with some missing values. Using numerical and categorical
  # variables.
  set.seed(123L);
  columns = c("A", "B", "C", "D", "E")
  l <- 250
  data <- data.frame(
    "A" = sample(1:10, size = l, replace = TRUE),
    "B" = sample(c(1:3, NA), size= l, replace = TRUE),
    "C" = sample(c(6:19, NA), size= l, replace = TRUE),
    "D" = sample(gl(4, 1), size = l, replace = TRUE),
    "E" = sample(as.character(c("female", "male", NA)),
                size = l, replace = TRUE),
    "F" = sample(as.character(c("other")),
                size = l, replace = TRUE)
  )

Compute the summary statistics using the R build-in `summary` function.

.. code-block:: r
  :caption: R summary function

  summary(data)
  #       A               B               C         D           E
  # Min.   : 1.00   Min.   :1.000   Min.   : 6.00   1:52   Length:250
  # 1st Qu.: 4.00   1st Qu.:1.000   1st Qu.: 9.00   2:63   Class :character
  # Median : 6.00   Median :2.000   Median :12.00   3:72   Mode  :character
  # Mean   : 6.04   Mean   :2.099   Mean   :12.31   4:63
  # 3rd Qu.: 9.00   3rd Qu.:3.000   3rd Qu.:15.25
  # Max.   :10.00   Max.   :3.000   Max.   :19.00
  #                 NA's   :68      NA's   :18
  #     F
  # Length:250
  # Class :character
  # Mode  :character

  var(data[,c("A", "B", "C")])
  # $A
  # [1] 8.215261

  # $C
  # [1] 15.25226

  # $B
  # [1] 0.6420982

Before we can start the federated analysis we need to split the dataset at least into
two parts:

.. code-block:: r
  :caption: Split the data

  # Split the data into two parts
  seperation_index <- floor(l / 3)

  d1 <- data[1:seperation_index, ]
  d2 <- data[(seperation_index + 1):l, ]
  datasets <- list(d1, d2)

Then we use the ``MockClient`` from vantage6. This client can be used to simulate
a federated vantage6 network.

.. code-block:: r
  :caption: MockClient

  # Initialize the mock client
  client <- vtg::MockClient$new(
    datasets = datasets,
    pkgname = "vtg.summary"
  )

  # We created two datasets (``d1``, ``d2``), so we send it also to two datasets
  organizations_to_include <- c(1, 2)

Finally we can run the federated analysis in the mock network. Note that we set the
``is_extend_data`` parameter to ``FALSE``. This means that EURACAN pre-processing
is not applied (which is impossible for the ``data`` we have defined).

.. code-block:: r
  :caption: Federated analysis

  federated_result <- vtg.summary::dsummary(
    client=client,
    columns=columns,
    types=NULL,
    organizations_to_include=organizations_to_include,
    is_extend_data=FALSE
  )
  # $nan_count
  # A  B  C  D  E
  # 0 68 18  0 90

  # $length
  #   A   B   C   D   E
  # 250 182 232 250 160

  # $range
  # [1]  1 19

  # $factor_counts
  # $factor_counts$D
  # $factor_counts$D$`1`
  # [1] 22

  # $factor_counts$D$`2`
  # [1] 26

  # $factor_counts$D$`3`
  # [1] 29

  # $factor_counts$D$`4`
  # [1] 28


  # $factor_counts$E
  # $factor_counts$E$female
  # [1] 53

  # $factor_counts$E$male
  # [1] 52



  # $mean
  #         A         B         C         D         E
  # 6.040000  2.098901 12.306034       NaN       NaN

  # $complete_rows
  # [1] 108

  # $complete_rows_per_node
  #   node complete_rows
  # 1    1            38
  # 2    2            70

  # $variance
  #         A          B          C          D          E
  # 8.2152610  0.6420982 15.2522578        NaN        NaN

  # $sd
  #         A         B         C         D         E
  # 2.8662277 0.8013103 3.9054139       NaN       NaN
