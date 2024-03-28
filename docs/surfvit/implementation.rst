Implementation
==============


.. uml::

  !theme superhero-outline

  caption The central part of the algorithm is responsible for the \
          orcastration and aggregation\n of the algorithm. The partial \
          parts are executed on each node.

  |client|
  :Request analysis;

  |central|
  :Collect organizations
  in collaboration;
  repeat
  :Create partial tasks;

  |partial|
  :RPC_time;

  |central|
  :Global event times;
  -> global unique event times;

  |partial|
  :RPC_at_risk;

  |central|
  :Compute global at risk
  and event counts;
  -> global at risk and event counts;

  |partial|
  :RPC_KMsurv;
  -> partial KM estimates;

  |central|
  :Sum partial KM estimates;
  -> global KM estimates;
  repeat while (strata left?)

  |client|
  :Receive analysis results;


Partials
--------

``RPC_time``
~~~~~~~~~~~~
The partial computes the unique event times from each dataset and shares these with
the aggregator.

``RPC_at_risk``
~~~~~~~~~~~~~~~
The partial obtains the at risk and event counts per timeslot and shares these with
the aggregator.

``RPC_KMsurv``
~~~~~~~~~~~~~~
The partial computes the Kaplan-Meier survival and risk estimates and shares these with
the aggregator.

.. math::

  S = \frac{N_{\text{event}}}{N_{\text{global at risk}}}

  R = \frac{N_{\text{event}}}{N_{\text{global at risk}} (N_{\text{global at risk}} - N_{\text{event}})}

``RPC_strata`` (optional)
~~~~~~~~~~~~~~~~~~~~~~~~~
Obtain unique levels of strata and share these with the aggregator. This is an optional
partial and is only executed if the user requests stratification.


Central (``dsurfvit``)
----------------------
The central part is responsible for the orcastration and aggregation of the algorithm.
Only the aggregation part is described here as the orcastration is not relevant for the
algorithm itself.

* | **Create unique global timeslots**
  The central part collect the unique event times from all nodes and computes the unique
  global event times. In case the user supplies ``timepoints`` as argument, this step
  is skipped.

* | **Compute global at risk and event counts**
  The central part collects the at risk and event counts from all nodes and computes the
  global at risk and event counts.

* | **Sum partial KM estimates**
  The central part collects the partial KM estimates from all nodes and sums these to
  obtain the global KM estimates.
