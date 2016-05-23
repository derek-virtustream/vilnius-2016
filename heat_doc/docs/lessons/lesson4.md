# Example #4: Templates and User Data
Now that we're provisioning our VMs programmatically, wouldn't it be nice if
we could _customize_ them so that we could change them automatically in
some way from the stock template? Turns out we're in luck! Heat provides
access to the _user data_ feature that's available to provision VM instances,
and even better, provides a _templating_ language that allows us to
customize the _user data_ based on our parameters and other resources.

In this example, we'll create the same VM as in the previous iteration, but
this time we'll customize it with a templated user data script.

## Additional Parameter
First we'll add a file that we'll download later on...
```yaml
parameters:
    ...
    random_file_to_get:
        type: string
        description: URL for some random file
        default: http://192.168.0.160:8080/v1/AUTH_49b7a2b12cb549a88762b9f044bbabe7/saltstuff/nyan.txt

```

## Templating
Then we'll add a template that contains placeholders for the values we want
to replace. This looks a lot like string interpolation in other languages.

```yaml
  user_data:
      str_replace:
          template: |
              #!/bin/bash
              echo 'Welcome to random VM $name_nonce friend!' > /etc/motd
              curl '$nyan' >> /etc/motd
          params:
              $name_nonce: {get_resource: name_nonce}
              $nyan: {get_param: random_file_to_get}
```

### Various data sources for templates
Note that there are a various ways of getting values:

* *get_param*: Gets a _parameter_ from the parameters section of the HOT file.
  we use that here to get the "name_nonce" random value from the parameters.
* *get_resource*: Gets a defined resource from the resources section of the HOT
  file. This allows you to reference other resources you've already created. In
  this case we're looking at a string value, but you can reference routers,
  networks, ports, etc.
* *get_attr*: Not show here, but allows you to drill down into subcomponents
  of other provisioned resources in the HOT file. Great for getting the other
  IPs of other servers, etc.


## All Together
```yaml
heat_template_version: 2014-10-16
description: Template to show off parameters

parameters:
    key_name:
        type: string
        label: Key Name
        description: SSH key to be used for all instances
        default: derek_ssh
    image_id:
        type: string
        label: Image ID
        description: Image to be used (RHEL/Centos 7 compat) for base OS
        default: 33a8bd11-7d16-47fe-b123-6c87a33d56da
    private_net_id:
        type: string
        description: ID of private network into which servers get deployed
        default: a00889c3-e373-47c2-8d8c-a64250e479f7
    random_file_to_get:
        type: string
        description: URL for the Salt Recipe stuff
        default: http://192.168.0.160:8080/v1/AUTH_49b7a2b12cb549a88762b9f044bbabe7/saltstuff/nyan.txt
resources:
    name_nonce:
        type: OS::Heat::RandomString
        properties:
            length: 8
            sequence: lowercase

    new_instance:
        type: OS::Nova::Server
        properties:
            key_name: { get_param: key_name }
            image: { get_param: image_id }
            flavor: m1.small
            name:
                str_replace:
                    template: random-vm-$NONCE
                    params:
                        $NONCE: { get_resource: name_nonce }
            networks:
              - network: private
            user_data:
                str_replace:
                    template: |
                        #!/bin/bash
                        echo 'Welcome to random VM $name_nonce friend!' > /etc/motd
                        curl '$nyan' >> /etc/motd
                    params:
                        $name_nonce: {get_resource: name_nonce}
                        $nyan: {get_param: random_file_to_get}

```
