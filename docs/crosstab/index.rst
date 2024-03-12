Crosstab
========
Cross-tab or also known as contingency table allows you to create a table of counts for
two or more categorical variables. For example, if we want to see the relationship
between the sex and the survival status of cancer patients, we can use the crosstab:

.. list-table::
   :widths: 10 10 10 10
   :header-rows: 1

   * -
     - Survived
     - Died
     - Total
   * - Male
     - 10
     - 20
     - 30
   * - Female
     - 30
     - 40
     - 70
   * - Total
     - 40
     - 60
     - 100

To learn how the contingency table is computed in a federated way, please refer to the
:doc:`/crosstab/implementation` section. The :doc:`/crosstab/usage` section provides
examples on how to use the `crosstab` function. The :doc:`/crosstab/privacy` section
discusses the privacy implications. The :doc:`/crosstab/validation` section discusses
the validation of the algorithm.


Authors
-------
Hasan Alradhi [1]_, Matteo Cellamare, Frank Martin [1]_, Bart van Beusekom [1]_, Anja van Gestel [1]_

.. [1] IKNL (Integraal Kankercentrum Nederland)

Source
------

The source code of the algorithm can be found in the
`EURACAN repository <https://github.com/iknl/v6-euracan-algorithms>`_.
A docker image can be used from:

.. code-block:: bash

  harbor2.vantage6.ai/starter/vtg.crosstab

Or when you want to use a specific version:

.. code-block:: bash

  harbor2.vantage6.ai/starter/vtg.summary:0.0.5


Contents
--------

.. toctree::
   :maxdepth: 2

   implementation
   usage
   privacy
   validation