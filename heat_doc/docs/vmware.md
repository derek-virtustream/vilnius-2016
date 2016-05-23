# How to setup your VMWare Workstation environment

## General:
This VMWare VM expects to be installed on a Network as described below, with
the IP already set at 192.168.4.131.

###Image:
* [Centos7-Openstack-Mitaka.vmwarevm.tar.gz](devops-pro-2016.armyofevilrobots.com/Centos7-Openstack-Mitaka.vmwarevm.tar.gz)
  is complete and ready to install. This is a VMWare image compatible with
  VMWare workstation, fusion, and should work with VMWare Player, although I
  haven't tested on that runtime.

###Credentials:

**The OS credentials are:**

* user: root
* pass: password

** The OpenStack Credentials are:**
```
unset OS_SERVICE_TOKEN
export OS_USERNAME=admin
export OS_PASSWORD=b93097488f034db4
export OS_AUTH_URL=http://192.168.4.131:5000/v2.0
export OS_TENANT_NAME=admin
export OS_REGION_NAME=RegionOne
```

## Networking:
The VM IP is configured statically at: ```192.168.4.131```
This OpenStack VM is preconfigured with a network that will hopefully not conflict
with our environment at Vilnius DevopsPro 2016. This is a dump of my configuration
on VMWare Fusion. You can also create this networking config on Workstation.
```
answer VNET_8_DHCP yes
answer VNET_8_HOSTONLY_NETMASK 255.255.255.0
answer VNET_8_HOSTONLY_SUBNET 192.168.4.0
answer VNET_8_NAT yes
answer VNET_8_VIRTUAL_ADAPTER yes
```
