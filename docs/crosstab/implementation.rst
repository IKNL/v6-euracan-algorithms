Implementation
==============

Overview
--------
The algorithm consists of two computation steps at the nodes. In the first step at the
node ``RPC_get_vars`` the unique levels(/categories/factors) are retrieved. Then in the
central part a global unqiue set of levels is computed. These are send in the second
step to the nodes. Then nodes compute the local contingency tables and send them to the
central part. The central part computes the global contingency table.

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
  :RPC_get_vars;

  |central|
  :Create global unique
  set of levels;
  -> global levels;

  |partial|
  :RPC_CT;

  |central|
  :Combine
  contingency tables;

  |client|
  :receive results;


Partials
--------
Partials are the computations that are executed on each node. The partials have access
to the data that is stored on the node. The partials are executed in parallel on each
node.

``RPC_get_vars``
~~~~~~~~~~~~~~~~
The partial retrieves the unique levels of the variables that are used in the
contingency table. The unique levels are send to the central part.

``RPC_CT``
~~~~~~~~~~
The partial computes the local contingency table. The local contingency table is
send to the central part.


Central (``dct``)
-----------------
The central part is responsible for the orcastration and aggregation of the algorithm.
Only the aggregation part is described here as the orcastration is not relevant for the
algorithm itself.

* | **Create global unique set of levels**:
  The central part creates a global unique set of levels. This is done by collecting the
  unique levels from each node and then computing the unique set of levels.

* | **Combine contingency tables**:
  The central part sums up the local contingency tables resulting in the global
  contingency table.


