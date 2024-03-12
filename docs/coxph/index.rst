CoxPH
=====
The Cox proportional-hazards model investigates the association between survival time
(such as time until an event occurs, like death or disease progression) and one or more
predictor variables. This implementation is based on the WEBDISCO paper [1]_.

.. [1] https://pubmed.ncbi.nlm.nih.gov/26159465/

Authors
-------
Melle Sieswerda [2]_, Matteo Cellamare, Frank Martin [2]_

.. [2] IKNL (Integraal Kankercentrum Nederland)


Source
------

The source code of the algorithm can be found in the
`EURACAN repository <https://github.com/iknl/v6-euracan-algorithms>`_.
A docker image can be used from:

.. code-block:: bash

  harbor2.vantage6.ai/starter/vtg.coxph

Or when you want to use a specific version:

.. code-block:: bash

  harbor2.vantage6.ai/starter/vtg.coxph:0.0.5


Contents
--------

.. toctree::
   :maxdepth: 2

   implementation
   usage
   privacy
   validation