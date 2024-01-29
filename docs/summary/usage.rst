Usage
=====

This expects you to be familiar with the vantage6 framework. If you are not, please
read the `documentation <https://docs.vantage6.ai>`_ first. Especially the part
about the `Python client <https://docs.vantage6.ai/en/main/user/pyclient.html>`_.

Input arguments
---------------
The algorithm accepts the following input arguments:

.. list-table::
   :widths: 20 80
   :header-rows: 1

   * - Argument
     - Description
   * - ``columns``
     - The names of the columns (features) to be included in the summary.
   * - ``types``
     - The types of the columns (features) to be included in the summary.
   * - ``subset_rules``
     - Settings to make subselections.
   * - ``organizations_to_include``
     - Which organizations to include in the summary.
   * - ``is_extend_data``
     - Whether to extend the data with the EURACAN preprocessing.



Example 1
---------

Compute the summary of the columns ``age``, ``bmi``, ``children`` and ``charges`` for
organizations 1, 2 and 3. We extend the data with the EURACAN preprocessing and do not
make any subselections.

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

Example 2
---------

The algorithm automatically convers character columns to factors. However a numerical
column can also be converted to a factor. This is done setting the type of the column
to ``factor``. In the example below we convert the column ``children`` to a factor.

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
          'types': {'children': 'factor'},
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
      description='Summary algorithm #2',
      image='harbor2.vantage6.ai/starter/summary',
      input=input_,
      data_format='json'
  )

  task_id = my_task.get('id')


Example 3
---------

The algorithm can make subselections. In the example below we make a subselection
of the data by selecting only the rows where the column ``children`` is equal to 0.

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
          'types': {'children': 'factor'},
          'organizations_to_include': [1,2,3],
          'subset_rules': [{'subset': 'children==0'}],
          'is_extend_data': True
      },
      'output_format': 'json'
  }

  my_task = client.task.create(
      collaboration=1,
      organizations=[1],
      name='Summary',
      description='Summary algorithm #3',
      image='harbor2.vantage6.ai/starter/summary',
      input=input_,
      data_format='json'
  )

  task_id = my_task.get('id')

