Summary
=======

The summary algorithm aims to provide statistics about the data per column. It will
return a list containing the following:

- ``nan_count`` representing each unique column's number of missing values
- ``length`` representing total length of each column across each site
- ``range`` a list of ranges per column
- ``mean`` a vector of means per column
- ``variance`` a vector of variance per column
- ``complete_rows_per_node`` the number of complete rows per node
- ``complete_rows`` is the sum of the complete rows per node

See how these are computed in the :doc:`/summary/implementation` section. See the
privacy considerations in the :doc:`/summary/privacy` section.

Authors
-------
Hasan Alradhi, Matteo Cellamare, Frank Martin, Bart van Beusekom, Anja van Gestel

Example
-------

.. code-block:: python

  from vantage6.client import Client

  # Create connection with the vantage6 server
  client = Client('http://localhost', 5000, '/api')
  client.setup_encryption(None)
  client.authenticate('root', 'password')

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
   validation
   usage
   privacy