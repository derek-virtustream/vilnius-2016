#Definitions#

##Flavor##
Or Flavour if you're from anywhere but the USA. This defines a variety of
details about the virtual hardware used for a VM:

* RAM
* CPU count
* Root disk size
* Additional ephemeral disk size
* Arch (i386 vs x86_64)
* Optional additional metadata

##Horizon##
This is the web-based UI for OpenStack

##HOT##
Short for Heat Orchestration Template. This is a Domain Specific Language based
on YAML which is used to define an OpenStack HEAT stack. OpenStack HEAT also
supports amazon Cloudformation templates, but we'll be ignoring that for this
introduction.

##Output##
When a HEAT template is deployed, the output is stored and can be reviewed
later on, either via the stack-show command, or in the Horizon dashboard. This
data is called the "Output".

##Parameters##
A HEAT template can include "Parameters" which allow for predefined and/or
modifiable details about the infrastructure to deploy. For example, a parameter
might be the ID of a VM Image to use for the HEAT template, allowing for
VM images to be modified or updated, while still deploying the same overall
architecture.

##ResourceGroup##
A group of resources. Used to group together, and multiply, a set of resources
inside of a template.

##Resources##
Resources are the specific objects that Heat will create and/or modify as part
of its operation. This can include infrastructure such as networks or
virtual machines, but can also include other metadata such as randomly generated
passwords.

##Stack##
A HEAT "stack" is the collection of objects or resources which will be created
by a HEAT template when deployed. This might include virtual machines, nics/ports, networks, routers, security groups, keypairs, auto-scaling rules, etc.

##Template##
A template is a YAML based declarative DSL which defines the state of a deployed
application stack.
