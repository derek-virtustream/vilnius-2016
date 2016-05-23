# Resource Groups and Multiple VMs
Now that we can parameterize our builds, customize the VMs, and generate
random values like passwords and nonces, wouldn't it be nice to be able
to provision more than one VM at a time? Even better, what if we could iterate
through a list of resources and generate them programmatically?

While HOT files are declarative, there are still structures for looping
over a series of values, and the syntax will be familiar to anybody that has
used a templating language before.

We're going to expand the template a lot this time, and add some new
features...

## Parameter Additions
### Slave Count
```yaml
    slave_count:
        type: number
        label: Slave Count
        description: Number of slaves
        default: 2
```

Here we are adding a _count_ value that defines the number of "slave" machines
that we're going to have in our new cluster. We'll iterate this count in a
[resource group](../glossary.md#resourcegroup) in order to create multiple
copies of the same VM, although each will be customized with a slightly
different identity.

### Flavors
```yaml
    master_flavor:
        type: string
        label: Master Instance Type
        description: Type of instance (flavor) to deploy for the master node
        default: m1.small
    slave_flavor:
        type: string
        label: Slave Instance Type
        description: Type of instance (flavor) to deploy
        default: m1.small
```

Here we are setting the [flavor](../glossary.md#flavor) for the master
and slave node(s) in the cluster. This allows us to change the
"virtual hardware" footprint of these VMs.

### Public net and Floating IPs
```yaml
    public_net_id:
        type: string
        description: ID of the public net
        default: de763108-53df-4d06-b553-af46bfede50e

```

Here we have specified the ID of the public network. This allows us to
reserve a new public IP that will be the external facing address of the
cluster. The feature underlying this is known as a "floating IP"

----
## Additions to the Master VM and it's Resources
```yaml
cluster_master_floating_ip:
    type: OS::Neutron::FloatingIP
    properties:
        floating_network_id: { get_param: public_net_id }
        port_id: { get_resource: cluster_master_port }

cluster_master_port:
    type: OS::Neutron::Port
    properties:
        network_id: { get_param: private_net_id }

```
Here, instead of allowing the default settings to define the
master VM's networking, we are being more specific by defining
the port _before_ the VM is provisioned. That way we can
generate the public IP and attach to the port, and more
importantly, we can KNOW that IP and reference it externally.

----

## The Resource Group
```yaml
    slaveresources:
        type: OS::Heat::ResourceGroup
        properties:
            count: { get_param: slave_count }
            resource_def:
```
The first few lines of our ResourceGroup name it (_slaveresources_), mark it
as an object of type ResourceGroup, and create a new property called _count_
which will define the number of times to duplicate the resources in the
_resource_def_. Note that it is possible to reference an _external_
_resource_def_ via a file inclusion, but we're putting it all in a single file
here for clarity.

### The Nested Resources
```yaml

                type: OS::Nova::Server
                properties:
                    key_name: { get_param: key_name }
                    image: { get_param: image_id }
                    flavor: { get_param: slave_flavor }
                    name:
                        str_replace:
                            template: slave-$NONCE-%index%
                            params:
                                $NONCE: { get_resource: name_nonce }
                    networks: [{network: { get_param: private_net_id}}]
                    user_data:
                        str_replace:
                            template: |
                                #!/bin/bash
                                echo "Welcome to random VM $HOSTNAME friend! > /etc/motd
                                curl '$nyan' >> /etc/motd
                            params:
                                $nyan: {get_param: random_file_to_get}
```
This stanza isn't much different from the one we have deployed
before, but it has a notable addition: The %index% field. This
is replaced with the count of VMs that has been created so
far, ie: 0, 1, 2, etc. This allows us to use the index in
setting parameters.

----
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
    slave_count:
        type: number
        label: Slave Count
        description: Number of slaves
        default: 2
    image_id:
        type: string
        label: Image ID
        description: Image to be used (RHEL/Centos 7 compat) for base OS
        default: 33a8bd11-7d16-47fe-b123-6c87a33d56da
    master_flavor:
        type: string
        label: Master Instance Type
        description: Type of instance (flavor) to deploy for the master node
        default: m1.small
    slave_flavor:
        type: string
        label: Slave Instance Type
        description: Type of instance (flavor) to deploy
        default: m1.small
    private_net_id:
        type: string
        description: ID of private network into which servers get deployed
        default: a00889c3-e373-47c2-8d8c-a64250e479f7
    public_net_id:
        type: string
        description: ID of the public net
        default: de763108-53df-4d06-b553-af46bfede50e
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

    cluster_master_floating_ip:
        type: OS::Neutron::FloatingIP
        properties:
            floating_network_id: { get_param: public_net_id }
            port_id: { get_resource: cluster_master_port }

    cluster_master_port:
        type: OS::Neutron::Port
        properties:
            network_id: { get_param: private_net_id }

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
              - port: { get_resource: cluster_master_port }  
            user_data:
                str_replace:
                    template: |
                        #!/bin/bash
                        echo 'Welcome to random VM $name_nonce friend!' > /etc/motd
                        curl '$nyan' >> /etc/motd
                    params:
                        $name_nonce: {get_resource: name_nonce}
                        $nyan: {get_param: random_file_to_get}

    slaveresources:
        type: OS::Heat::ResourceGroup
        properties:
            count: { get_param: slave_count }
            resource_def:
                type: OS::Nova::Server
                properties:
                    key_name: { get_param: key_name }
                    image: { get_param: image_id }
                    flavor: { get_param: slave_flavor }
                    name:
                        str_replace:
                            template: slave-$NONCE-%index%
                            params:
                                $NONCE: { get_resource: name_nonce }
                    networks: [{network: { get_param: private_net_id}}]
                    user_data:
                        str_replace:
                            template: |
                                #!/bin/bash
                                echo "Welcome to slave VM $HOSTNAME friend!" > /etc/motd
                                curl '$nyan' >> /etc/motd
                            params:
                                $nyan: { get_param: random_file_to_get }

```
