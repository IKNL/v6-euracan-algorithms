Privacy
=======

Guards
------
There are several gaurds in place to protect the privacy of the individual records:

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
      - Aggregator, Data Station
      - Low
    * - (Local) Unique levels / factors
      - Data station
      - Aggregator
      - Low
    * - Global unique levels / factors
      - Aggregator
      - Data station
      - Low
    * - (Local) Contingency table
      - Data station
      - Aggregator
      - Low
    * - Global contingency table
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

*