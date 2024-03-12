Privacy
=======

Guards
------
There are several privacy guards in place to protect privacy of the individual records.

* ...

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

  The implementation details can be found in :doc:`./implementation`.

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
      - Aggregator, Data stations
      - Low
    * - (local) Unique event times
      - Data station(s)
      - Aggregator
      - Low - High
    * - Global unique event times
      - Aggregator
      - Data station(s)
      - Low - High
    * - Sum of explanatory variables
      - Data station(s)
      - Aggregator
      - Low
    * - Beta(s)
      - Aggregator
      - Data station(s)
      - Low
    * - Aggregate 1
      - Data station(s)
      - Aggregator
      - Low
    * - Aggregate 2
      - Data station(s)
      - Aggregator
      - Low
    * - Aggregate 3
      - Data station(s)
      - Aggregator
      - Low
    * - Final model
      - Aggregator
      - Client
      - Low

Vunerability to Known Attacks
-----------------------------

.. TODO FM 30-01-2024: We should add a glossary with the attacks and their description.

.. list-table::
    :widths: 25 10 65
    :header-rows: 1

    * - Attack
      - Applicable
      - Risk analysis
    * - Reconstruction
      - ⚠
      - Unique event times are shared
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

*



