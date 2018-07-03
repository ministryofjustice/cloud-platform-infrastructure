# export Auth0 settings
This uses the [Auth0 Python](https://github.com/auth0/auth0-python) library and calls the [Auth0 management APIs](https://auth0.com/docs/api/management/v2)
At first glance, the API seems incomplete and inconsistent, I have created a ticket with Auth0 asking for clarification if it is useable for backup purposes.

Error in `a.users.list()`:
```
  File "/usr/lib/python3.4/site-packages/auth0/v3/management/rest.py", line 128, in content
    message=self._error_message())
auth0.v3.exceptions.Auth0Error: 400: Bad Request
```
Useless output `a.tenants.get()`:
```
{'flags': {'disable_impersonation': True},
 'sandbox_version': '4',
 'sandbox_versions_available': ['8']}
```
Correct output, for `a.connections.all()`:
```
[{'enabled_clients': ['KQ...XD',
                      'Sk...U6'],
  'id': 'con_wE...Xv',
  'is_domain_connection': False,
  'name': 'Username-Password-Authentication',
  'options': {'brute_force_protection': True,
              'mfa': {'active': True, 'return_enroll_settings': True},
              'passwordPolicy': 'good',
              'strategy_version': 2},
  'realms': ['Username-Password-Authentication'],
  'strategy': 'auth0'},
 {'enabled_clients': ['KQ...XD',
                      'Sk...U6'],
  'id': 'con_Xn...Ir',
  'is_domain_connection': False,
  'name': 'github',
  'options': {'admin_org': False,
              'admin_public_key': False,
              'admin_repo_hook': False,
              'client_id': '12...95',
              'client_secret': '80...c9',
              'delete_repo': False,
              'email': True,
              'follow': False,
              'gist': False,
              'notifications': False,
              'profile': True,
              'public_repo': False,
              'read_org': False,
              'read_public_key': False,
              'read_repo_hook': False,
              'read_user': True,
              'repo': False,
              'repo_deployment': False,
              'repo_status': False,
              'scope': ['user:email', 'read:user'],
              'write_org': False,
              'write_public_key': False,
              'write_repo_hook': False},
  'realms': ['github'],
  'strategy': 'github'}]
```