How to use
==========

Input arguments
---------------


.. list-table::
   :widths: 20 80
   :header-rows: 1

   * - Argument
     - Description
   * - ``formula``
     - Formula indicating the ``time``, ``time2``, ``status`` and ``expl_var``
   * - ``conf.int``
     - Confidence interval coverage (95% default)
   * - ``conf.type``
     - Type of confidence interval: log, identity or log-log (log default)
   * - ``plotCI``
     - Whether to plot the confidence interval (TRUE default)
   * - ``timepoints``
     - Time points to calculate KM (bins instead of individual time point)
   * - ``subset_rules``
     - Settings to make subselections.
   * - ``organizations_to_include``
     - Which organizations to include in the summary.
..   * - ``is_extend_data``
..     - Whether to extend the data with the EURACAN preprocessing.


Example 1
---------

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
    'method': 'dsurvfit',
    'args': [],
    'kwargs': {
        'conf.int': 0.95,
        'conf.type': 'log',
        'timepoints': None,
        'plotCI': TRUE,
        'formula': "Surv(time, status) ~ expl_var",
        'organizations_to_include': [1,2,3],
        'subset_rules': None
    },
    'output_format': 'json'
  }

  my_task = client.task.create(
      collaboration=1,
      organizations=[1],
      name='Surfvit',
      description='Survfit algorithm #1',
      image='harbor2.vantage6.ai/starter/vtg.survfit:latest',
      input=input_,
      data_format='json'
  )

  task_id = my_task.get('id')


