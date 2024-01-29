Privacy
=======

Gaurds
------
There are several privacy gaurds in place to protect privacy of the individual records.

* The number of observations, after removing the ``NA`` values from each column, need to
  be at least higher than the ``VTG_SUMMARY_THRESHOLD`` threshold (default 5) to be
  included in the output.
* Each factor level in each column needs to have at least ``VTG_SUMMARY_THRESHOLD``
  (default 5) observations to be included in the output.
* The number of complete observations (no ``NA`` values) needs to be at least
  ``VTG_SUMMARY_THRESHOLD`` (default 5) to be included in the output.

Shared Data
-----------
Data that is shared by the data stations with the aggregator is the following:

* The algorithms shares ``min``, ``max``, ``counts``, ``sums``, ``factors`` with the
  vantage6-server. To be more specific, for all columns :math:`d_i` in the data, the
  following is shared:

  * count and sum of :math:`d_i`
  * variance of :math:`d_i` (computed using the global mean)
  * Number ``NA`` values in :math:`d_i`
  * Number of observations in :math:`d_i` (without ``NA`` values)
  * When dealing with a numeric columns te range of :math:`d_i` (min and max)

    * if :math:`d_i` is a factor, the number of observations for each factor level is
      shared.
    * if :math:`d_i` is a numeric, the sum of all observations is shared.

  Implementation details can be found in :doc:`./implementation`.

There are four types of parties handling data in the algorithm; (1) The aggregator,
(2) the data stations, (3) the client and (4) the vantage6 server. See
:doc:`./implementation` for a swimlane diagram. Note that the server is not displayed as
it merely acts  as a communication hub between data station, aggregator and researcher.


.. list-table::
    :widths: 34 11 11 11
    :header-rows: 1

    * - Description
      - Source
      - Destination
      - Risk
    * - User input
      - Client
      - Aggregator, Data Station
      - Low
    * - ``min``, ``max``, ``counts``, ``sums``, ``factors``
      - Data Station
      - Aggregator
      - Low
    * - Global ``mean``
      - Aggregator
      - Data Station
      - Low
    * - Global ``min``, ``max``, ``counts``, ``sums``, ``factors``
      - Aggregator
      - Client
      - Low

Vunerability to Known Attacks
-----------------------------

.. list-table::
    :widths: 25 10 65
    :header-rows: 1

    * - Attack
      - Applicable
      - Risk analysis
    * - Reconstruction
      - ❌
      -
    * - Differencing
      - ✔
      - Possible by making smart selection using the pre-processing step.
    * - Deep Leakage from Gradients (DLG)
      - ❌
      -
    * - Generative Adversarial Networks (GAN)
      - ❌
      -
    * - Model Inversion
      - ❌
      -
    * - Watermak Attack
      - ❌
      -

Prevention / Mitigation
-----------------------

* To increase the privacy level of the algorithm, the ``VTG_SUMMARY_THRESHOLD`` can be
  increased. This can only be done when there is sufficient data available. (It is also
  possible to decrease the threshold, but this will decrease the privacy level.)



