How to use
==========
To understand the information on this page, you should be familiar with the vantage6
framework. If you are not, please read the `documentation <https://docs.vantage6.ai>`_
first. Especially the part about the `Python client <https://docs.vantage6.ai/en/main/user/pyclient.html>`_.

Input arguments
---------------

.. list-table::
   :widths: 20 80
   :header-rows: 1

   * - Argument
     - Description
   * - ``expl_vars``
     - list of explanatory variables (covariates) to use
   * - ``time_col``
     - name of the column that contains the event/censor times
   * - ``censor_col``
     - name of the column that explains whether an event occurred or the patient was
       censored
   * - ``types``
     - list of types of the columns in the dataset
   * - ``subset_rules``
     - Settings to make subselections.
   * - ``organizations_to_include``
     - Which organizations to include in the summary.


Example 1
---------
Compute the CoxPH for explanatory variables BMI and b02_edu, with the time column
``surv`` and the censor column ``deadOS``. The organizations to include are 1, 2 and 3.
We also do not include any subsetting.

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
    'method': 'dcoxph',
    'args': [],
    'kwargs': {
        'expl_vars': ["BMI", "b02_edu"],
        'time_col': "surv",
        'censor_col': "deadOS",
        'types': None,
        'organizations_to_include': [1,2,3],
        'subset_rules': []
    },
    'output_format': 'json'
  }

  my_task = client.task.create(
      collaboration=1,
      organizations=[1],
      name='CoxPH',
      description='CoxPH algorithm #1',
      image='harbor2.vantage6.ai/starter/vtg.coxph:latest',
      input=input_,
      data_format='json'
  )

  task_id = my_task.get('id')