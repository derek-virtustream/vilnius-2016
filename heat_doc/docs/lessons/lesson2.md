# Example #2: A Single VM - Via the Command Line
Here we revisit our "hello world" deployment, but this time from the command
line. While it's also possible to use [cURL](https://curl.haxx.se/) to
deploy HEAT templates, the OpenStack foundation have built a set of nice
command line clients to perform most actions you need in OpenStack.

## The openstackclient command line tool
The new python-openstack client is now the preferred 'unified' command line
tool for performing actions against openstack. It's very straightforward to
install on OSX/Linux/Windows: `pip install openstackclient`.

For more detailed installation instructions, see
[openstackclient installation](http://docs.openstack.org/cli-reference/common/cli_install_openstack_command_line_clients.html)

## Using the command line client

```bash
±% openstack stack create -f yaml -t docs/media/lesson1.hot lesson1direct                                                 !11094
id: d8d767f8-028d-4340-8f63-bba6d071145f
stack_name: lesson1direct
description: The SMALLEST possible working HEAT template
creation_time: '2016-05-08T23:23:59'
updated_time: null
stack_status: CREATE_IN_PROGRESS
stack_status_reason: Stack CREATE started

±% openstack stack list                                                                                                   !11096
+--------------------------------------+---------------+-----------------+---------------------+--------------+
| ID                                   | Stack Name    | Stack Status    | Creation Time       | Updated Time |
+--------------------------------------+---------------+-----------------+---------------------+--------------+
| d8d767f8-028d-4340-8f63-bba6d071145f | lesson1direct | CREATE_COMPLETE | 2016-05-08T23:23:59 | None         |
| d70f465b-a0ea-4eb4-b0ea-0e2eef4ae30a | testlesson1   | CREATE_COMPLETE | 2016-05-08T22:41:13 | None         |
+--------------------------------------+---------------+-----------------+---------------------+--------------+
```
