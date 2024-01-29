Implementation
==============


Overview
--------
The algorithm consists of two computation steps at the nodes. The two step approach
is necessary as the variance computation requires the global mean of each column.

.. uml::

  !theme superhero-outline

  caption The central part of the algorithm is responsible for the \
          orcastration and aggregation\n of the algorithm. The partial \
          parts are executed on each node.

  |client|
  :request analysis;

  |central|
  :collect organizations
  in collaboration;
  :create partial tasks;

  |partial|
  :RPC_summary;

  |central|
  :Aggragate summary results;
  -> global mean;

  |partial|
  :RPC_variance_sum;


  |central|
  :collect results from
  all organizations;

  |client|
  :receive results;


Partials
--------

``RPC_summary``
~~~~~~~~~~~~~~~
Each nodes computes the following statistics:

* | **NA counts**
  | Computes the number of NANs in each column.

  .. code-block:: R

    colSums(is.na(data))


* | **Column lengths**
  | Computes the number of non-NANs in each column.

  .. code-block:: R

    colSums(!is.na(data))

* | **Column sums**
  | Computes the sum of each column if the column is numerical.

  .. code-block:: R

    sum(data[, column_name])

* | **Column ranges**
  | Computes the range of each column if the column is numerical.

  .. code-block:: R

    # min
    summary(data[, column_name])["Min."]

    # max
    summary(data[, column_name])["Max."]


* | **Factor Counts**
  | Computes the number of occurences of each factor in each column.

  .. code-block:: R

    # counts
    summary(data[, column_name])


``RPC_variance_sum``
~~~~~~~~~~~~~~~~~~~~
Computes the variance of each column if the column is numerical. This function requires
the output of ``RPC_summary`` as it needs the global mean from each column.

* | **Column variances**
  | Compute the variance of each column if the column is numerical. It uses the global
  | ``mean`` (:math:`\mu_{global}`) from each column. This global mean is computed using
  | the input from ``RPC_summary`` function. Note that we do not actually compute the
  | variance but the sum of squared differences from the mean. This is because we need
  | to aggregate the results from each node and the variance is not aggregatable.

  .. math::

    S_j = \sum_{i=1}^{n} (d_i - \mu_{global})^2

  | with :math:`S_j` being the sum of squared differences from node :math:`j` and :math:`d_i` being the data point :math:`i` in column :math:`d`.

  .. code-block:: R

    # Sum of squared differences from the mean
    sum((data[, column] - mean[[column]])^2)


Central
-------
The central part of the algorithm is responsible for the orcastration and aggregation
of the algorithm. Only the aggregation part is described here as the orcastration is
not relevant for the algorithm itself.

* | **NA counts / Column lengths / Column sums**
  | The NA counts, column lengths and column sums produced by ``RPC_summary`` are
  | aggregated by summing up the results from each node:

  .. code-block:: R

    # with ``results`` being either the NA counts, column lengths or column sums:
    sum(results)



* | **Column ranges**
  | The column ranges computed by ``RPC_summary`` are aggregated by taking the minimum
  | of the minimums and the maximum of the maximums.

  .. code-block:: R

    # min
    min(mins)

    # max
    max(maxs)

* | **Factor Counts**
  | The factor counts produced by ``RPC_summary`` are aggregated by summing up the
  | results from each node. It sums all the counts for each factor in each column.

  .. code-block:: R

    # with ``counts`` being the count for each factor in each column:
    sum(counts)

* | **Column variances**
  | The column variances produced by ``RPC_variance_sum`` are aggregated by summing
  | up the results from each node.

  .. math::

    \frac{1}{(n - 1)}\sum_{j=1}^{n} S_j

  .. code-block:: R

    # with ``variances`` being the variance for each numerical column:
    sum(variances) / (n - 1)
