Privacy
=======

Guards
------
There are several privacy guards in place to protect privacy of the individual records.

* The number of observations, after removing the ``NA`` values from each column, need to
  be at least higher than the ``VTG_PREPROCESS_MIN_RECORDS_THRESHOLD`` threshold
  (default 5) to be included in the output.
* ...

Shared Data
-----------

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
    * - (Local) Unique event times
      - Data station(s)
      - Aggregator
      - Low
    * - Global unique event times
      - Aggregator
      - Data station(s)
      - Low
    * - (Local) At risk and event counts
      - Data station(s)
      - Aggregator
      - Low
    * - Global at risk and event counts
      - Aggregator
      - Data station(s)
      - Low
    * - Local Kaplan-Meier estimates
      - Data station(s)
      - Aggregator
      - Low
    * - Global Kaplan-Meier estimates
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

*



