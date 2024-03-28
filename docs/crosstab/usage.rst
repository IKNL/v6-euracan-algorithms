How to use
==========

Input arguments
---------------

.. list-table::
   :widths: 20 80
   :header-rows: 1

   * - Argument
     - Description
   * - ``f``
     - Formula used to select the variables for the crosstab
   * - ``subset_rules``
     - Settings to make subselections.
   * - ``organizations_to_include``
     - Which organizations to include in the summary.
   * - ``is_extend_data``
     - Whether to extend the data with the EURACAN preprocessing.


Example 1
---------

Compute a crosstab for the variables ``var1`` and ``var2``.

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

  input_ = {
      'master': True,
      'method': 'dct',
      'args': [],
      'kwargs': {
          'f': '~ var1 + var2',
          'organizations_to_include': [1,2,3],
          'subset_rules': None
      },
      'output_format': 'json'
  }

  my_task = client.task.create(
      collaboration=1,
      organizations=[1],
      name='Crosstabs',
      description='Crosstabs algorithm #1',
      image='harbor2.vantage6.ai/starter/crosstab:latest',
      input=input_,
      data_format='json'
  )

  task_id = my_task.get('id')