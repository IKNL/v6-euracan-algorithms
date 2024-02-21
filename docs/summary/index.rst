Summary
=======

The summary algorithm aims to provide statistics about the data per column. It took
inspiration from the R build-in function
`summary <https://www.rdocumentation.org/packages/base/versions/3.6.2/topics/summary>`_.
It will return a list containing the following:

.. list-table::

  * - Output
    - Description
  * - ``nan_count``
    - number of missing values per column
  * - ``length``
    - total length of each column across each site (excluding missing values)
  * - ``range``
    - a list of ranges per numerical column
  * - ``mean``
    - a list of means per numerical column
  * - ``variance``
    - a list of variances per numerical column
  * - ``factor_counts``
    - a list of dictionaries containing the number of occurrences of each unique value per categorical column
  * - ``complete_rows_per_node``
    - the number of complete rows
  * - ``complete_rows``
    - the number of complete rows

To learn how these are calculated, refer to the :doc:`/summary/implementation` section.
The :doc:`/summary/privacy` section discusses the privacy implications. The
:doc:`/summary/validation` section discusses the validation of the algorithm.

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

  harbor2.vantage6.ai/starter/vtg.summary

Or when you want to use a specific version:

.. code-block:: bash

  harbor2.vantage6.ai/starter/vtg.summary:0.0.1

Example Usage
-------------

.. TODO FM 30-01-2024: remove the output_format from the example when releaseing for
    vantage6 v4+.

.. code-block:: python

  from vantage6.client import Client

  server = 'http://localhost'
  port = 5000
  api_path = '/api'
  private_key = None
  username = 'root'
  password = 'password'

  # Create connection with the vantage6 server
  client = Client(server, port, api_path)
  client.setup_encryption(private_key)
  client.authenticate(username, password)

  input_ ={
      'master': True, 'method': 'dsummary', 'args': [],
      'kwargs': {
          'columns': ['age', 'bmi', 'children', 'charges'],
          'organizations_to_include': [1,2,3],
          'subset_rules': [],
          'is_extend_data': True
      },
      'output_format': 'json'
  }

  my_task = client.task.create(
      collaboration=1,
      organizations=[1],
      name='Summary',
      description='Summary algorithm #1',
      image='harbor2.vantage6.ai/starter/summary',
      input=input_,
      data_format='json'
  )

  task_id = my_task.get('id')


See more in the :doc:`/summary/usage` section.


Contents
--------

.. toctree::
   :maxdepth: 2

   implementation
   usage
   privacy
   validation