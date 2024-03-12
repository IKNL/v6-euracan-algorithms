Implementation
==============


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
  :RPC_get_unique_event_times_and_counts;
  :RPC_compute_summed_z;

  |central|
  :Compute global
  unique event times;
  :Compute global z_hat;
  repeat
  :Create partial tasks;
  -> unique event times;

  |partial|
  :RPC_perform_iteration;

  |central|
  :compute derivatives;
  :compute betas;
  repeat while (is convergered?);
  -> yes;

  |client|
  :receive results;


Partials
--------
Partials are the computations that are executed on each node. The partials have access
to the data that is stored on the node. The partials are executed in parallel on each
node.

``RPC_get_unique_event_times_and_counts``
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
The partial obtains the unique event times from each dataset. These are the times at
which the events occur. These event times are then send to the central part.

``RPC_compute_summed_z``
~~~~~~~~~~~~~~~~~~~~~~~~
The partial computes the sum for each of the z values (explanatory variables) for all
records where the event occurs.

``RPC_perform_iteration``
~~~~~~~~~~~~~~~~~~~~~~~~~
Three aggregates are required for each itteration from each node in order to update
the :math:`\beta`\s for the next itteration. These aggregates are part of the first and
second order derivatives of the log likelihood function. The aggregates are:

* | **Aggregate 1**
  This is basically multiplying the patients explanatory variables with the
  :math:`\beta`, then exponentiating the result and finally summing the result for all
  patients.

  .. math::

    \sum_l \exp\Bigl(\beta^T z^l\Bigr)

  In which :math:`z^l` is the :math:`l`-th subject explanatory variable values. The
  final result is a scalar value.

* | **Aggregate 2**
  Similar to the first aggregate, but now the result is multiplied with the subjects
  explanatory variables.

  .. math::

    \sum_l z \exp\Bigl(\beta^T z^l\Bigr)

  In which :math:`z` is the :math:`l`-th subject explanatory variable values. The final
  result is a vector with the same length as the number of explanatory variables.

* | **Aggregate 3**
  Similar to the second aggregate, but now the result is multiplied with the subjects
  explanatory variables and then summed.

  .. math::

    \sum_l (z^{l})^T z^l \exp\Bigl(\beta^T z^l\Bigr)

  In which :math:`z` is the :math:`l`-th subject explanatory variable values. The final
  result is a sqaure matrix with the same size as the number of explanatory variables.


Central (``dcoxph``)
--------------------
The central part is responsible for the orcastration and aggregation of the algorithm.
Only the aggregation part is described here as the orcastration is not relevant for the
algorithm itself.

* | **Compute global unique event times**
  The central part collects the unique event times from all nodes and computes the
  global unique event times.

* | **Compute global z_hat**
  The central part collects the summed z values from all nodes and computes the global
  summed z values. This is basically the sum of the z values for all records where the
  event occurs.

* | **Compute derivatives**
  The central part collects the aggregates from all nodes and computes the first
  :math:`l^{'}` and second order :math:`l^{''}` derivatives of the log likelihood
  function.

* | **Compute betas**
  The central part updates the :math:`\beta` values for the next itteration using:

  .. math::

    \beta^{\tau} = \beta^{\tau-1} - \Bigl(l^{''}\bigl(\beta^{\tau-1}\bigr)\Bigr)^{-1}
    l^{'} \bigl(\beta^{\tau-1}\bigr)
