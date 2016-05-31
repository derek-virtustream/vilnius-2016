# Putting It All Together, and Adding Config Management
Now that we've built out our virtual compute cluster, we need to actually
deploy an application stack to it.

In this example, we're going to deploy the same stack as the last time, but
then we'll deploy a configuration management system on top, which allows
us to then deploy any combination of applications. In this demo, we'll be
deploying SaltStack, but if you would rather use Puppet, Chef, Ansible,
or some other engine, you could use the same approach.

## Installing Prerequisites via User-Scripts
```yaml
  [[ -e /usr/bin/git ]] || yum install -y tar wget git
  [[ -e /etc/yum.repos.d/epel-apache-maven.repo ]] || wget http://repos.fedorapeople.org/repos/dchen/apache-maven/epel-apache-maven.repo -O /etc/yum.repos.d/epel-apache-maven.repo
  [[ -e /etc/yum.repos.d/salt-2015.8.repo ]] || rpm -Uvh https://repo.saltstack.com/yum/redhat/salt-repo-2015.8-3.el7.noarch.rpm
  [[ -e /etc/yum.repos.d/epel.repo ]] || yum install -y epel-release
  #yum clean expire-cache
  #yum -y update
  [[ -e /usr/bin/salt-minion ]] || yum -y install salt-master salt-ssh salt-syndic salt-cloud salt-api salt-minion
  ... etc ...
  rpm -q salt-master && chkconfig salt-master on && systemctl start salt-master #Make sure salt is running.
  rpm -q salt-minion && chkconfig salt-minion on && systemctl start salt-minion #Make sure salt is running.
```
The first thing we do is get a configuration management tool installed. This allows
us to manage the state of the VM with much more control than just shell scripts
would allow. Note that similar code appears in both the master and slave VM
user-scripts. I've also placed guards around the installation so that the packages
don't call yum unless they are missing, to avoid latency on the VM build in the
case that we have a specialized VM image prepared.

## High-stating the config
```yaml
while [[ $(/usr/bin/salt-key --list=acc --out=newline_values_only | wc -l) -le $slave_count ]]; do \
sleep 5; \
/usr/bin/salt-key -y -a 'demo-*-$cluster_nonce*'; \
done
sleep 20 # It can take a bit for salt minions to restart after registration...
salt '*' test.ping --out raw -t 300
salt 'demo-slave*' saltutil.refresh_pillar -t 30
salt --no-color 'demo-slave*' state.highstate -t 300 >> /var/log/highstate
sleep 3
salt --no-color 'demo-master-*' state.highstate -t 300 >> /var/log/highstate
```
Now that salt is installed, we take several steps:
### Accepting all the minions

1. We wait for the minions to join. Note that normally, and for larger installs,
   it makes more sense to use the salt [reactor](https://docs.saltstack.com/en/latest/topics/reactor/) feature to
   handle incoming minion events, but in this case we're doing things in a simpler
   manner, so we're just waiting for _all_ the minions to join, since we know how many
   there should be.
2. We highstate the "slave" minions, where the web application runs. This has the
   side effect of populating the pillar data with the details about the running
   Web application servers
3. We finally highstate the nginx server/proxy, making the application accessible.

## Testing out the results
When we visit the http://$HOSTNAME/ of the master, we should see the proxied web
application.

## All together now
```yaml
heat_template_version: 2014-10-16
description: Template for deploying demo infrastructure

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
        #default: 33a8bd11-7d16-47fe-b123-6c87a33d56da
        default: minimal_salt_centos_7.2
    slave_count:
        type: number
        label: Slave Count
        description: Number of slaves
        default: 2
    master_flavor:
        type: string
        label: Master Instance Type
        description: Type of instance (flavor) to deploy
        default: m1.mini
    slave_flavor:
        type: string
        label: Slave Instance Type
        description: Type of instance (flavor) to deploy
        default: m1.mini
    public_net_id:
        type: string
        description: ID of the public net
        default: ext-net
    private_net_id:
        type: string
        description: ID of private network into which servers get deployed
        default: private
    private_subnet_id:
        type: string
        description: ID of private sub network into which servers get deployed
        default: private-subnet
    demo_config_url:
        type: string
        description: URL for the demo Recipe stuff
        default: http://devops-pro-2016.armyofevilrobots.com.s3.amazonaws.com/media/demo_stuff.tar.gz
        #default: http://192.168.0.160:8080/v1/AUTH_49b7a2b12cb549a88762b9f044bbabe7/saltstuff/demo_stuff.tar.gz
        #default: http://192.168.4.131:8080/v1/AUTH_ee6ad2970c12487082c85b897c5e29e7/SaltStuff/demo_stuff.tar.gz

resources:
    root_pw:
        type: OS::Heat::RandomString

    cluster_nonce:
        type: OS::Heat::RandomString
        properties:
            length: 6
            sequence: lowercase

    demo_security_group:
        type: OS::Neutron::SecurityGroup
        properties:
            description: Add security group rules for server
            name:
                str_replace:
                    template: demo-secgroup-$NONCE
                    params:
                        $NONCE: { get_resource: cluster_nonce }
            rules:
              - remote_ip_prefix: 0.0.0.0/0
                protocol: tcp
                port_range_min: 80
                port_range_max: 80
              - remote_ip_prefix: 0.0.0.0/0
                protocol: tcp
                port_range_min: 9876
                port_range_max: 9876
              - remote_ip_prefix: 0.0.0.0/0
                protocol: tcp
                port_range_min: 22
                port_range_max: 22
              - remote_ip_prefix: 0.0.0.0/0
                protocol: icmp

    cluster_master_floating_ip:
        type: OS::Neutron::FloatingIP
        properties:
            floating_network_id: { get_param: public_net_id }
            port_id: { get_resource: cluster_master_port }

    cluster_master_port:
        type: OS::Neutron::Port
        properties:
            network_id: { get_param: private_net_id }
            fixed_ips:
              - subnet_id: { get_param: private_subnet_id }
            security_groups: [{ get_resource: demo_security_group }]

    cluster_master:
        type: OS::Nova::Server
        properties:
            key_name: { get_param: key_name }
            image: { get_param: image_id }
            flavor: { get_param: master_flavor }
            name:
                str_replace:
                    template: demo-master-$NONCE
                    params:
                        $NONCE: { get_resource: cluster_nonce }
            networks:
              - port: { get_resource: cluster_master_port }
            user_data:
                str_replace:
                    template: |
                        #!/bin/bash -v
                        [[ -e /usr/bin/git ]] || yum install -y tar wget git
                        [[ -e /etc/yum.repos.d/epel-apache-maven.repo ]] || wget http://repos.fedorapeople.org/repos/dchen/apache-maven/epel-apache-maven.repo -O /etc/yum.repos.d/epel-apache-maven.repo
                        [[ -e /etc/yum.repos.d/salt-2015.8.repo ]] || rpm -Uvh https://repo.saltstack.com/yum/redhat/salt-repo-2015.8-3.el7.noarch.rpm
                        [[ -e /etc/yum.repos.d/epel.repo ]] || yum install -y epel-release
                        #yum clean expire-cache
                        #yum -y update
                        [[ -e /usr/bin/salt-minion ]] || yum -y install salt-master salt-ssh salt-syndic salt-cloud salt-api salt-minion
                        echo "$master_ip salt salt-master-$cluster_nonce" >> /etc/hosts
                        (
                        echo "$ROOT_PW"
                        echo "$ROOT_PW"
                        ) | passwd --stdin root
                        rpm -q salt-master && chkconfig salt-master on && systemctl start salt-master #Make sure salt is running.
                        rpm -q salt-minion && chkconfig salt-minion on && systemctl start salt-minion #Make sure salt is running.
                        echo "*/5 * * * * root /usr/bin/salt-key -y -a 'demo-*-$cluster_nonce*'" > /etc/cron.d/salt-autoaccept
                        curl -s "$demo_cfg_url" | tar xz  -C /srv/
                        cp /srv/salt/demo/files/mine.conf /etc/salt/minion.d/mine.conf
                        cp /srv/salt/demo/files/peers.conf /etc/salt/master.d/peers.conf
                        # Note; we do a -le compare here, so that it's slaves + master, ie 2 -le (2+1) where 2+1 == 2 slaves and 1 master
                        while [[ $(/usr/bin/salt-key --list=acc --out=newline_values_only | wc -l) -le $slave_count ]]; do \
                        sleep 5; \
                        /usr/bin/salt-key -y -a 'demo-*-$cluster_nonce*'; \
                        done
                        sleep 20 # It can take a bit for salt minions to restart after registration...
                        salt '*' test.ping --out raw -t 300
                        salt 'demo-slave*' saltutil.refresh_pillar -t 30
                        salt --no-color 'demo-slave*' state.highstate -t 300 >> /var/log/highstate
                        sleep 3
                        salt --no-color 'demo-master-*' state.highstate -t 300 >> /var/log/highstate


                    params:
                        $master_ip: {get_attr: [cluster_master_port, fixed_ips, 0, ip_address]}
                        $ROOT_PW: {get_resource: root_pw}
                        $cluster_nonce: {get_resource: cluster_nonce}
                        $demo_cfg_url: {get_param: demo_config_url}
                        $slave_count: { get_param: slave_count }


    rg:
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
                            template: demo-slave-$NONCE-%index%
                            params:
                                $NONCE: { get_resource: cluster_nonce }
                    networks: [{network: { get_param: private_net_id}}]
                    security_groups: [{ get_resource: demo_security_group }]
                    user_data:
                        str_replace:
                            template: |
                                #!/bin/bash -v
                                [[ -e /usr/bin/git ]] || yum install -y tar wget git
                                [[ -e /etc/yum.repos.d/epel-apache-maven.repo ]] || wget http://repos.fedorapeople.org/repos/dchen/apache-maven/epel-apache-maven.repo -O /etc/yum.repos.d/epel-apache-maven.repo
                                [[ -e /etc/yum.repos.d/salt-2015.8.repo ]] || rpm -Uvh https://repo.saltstack.com/yum/redhat/salt-repo-2015.8-3.el7.noarch.rpm
                                [[ -e /etc/yum.repos.d/epel.repo ]] || yum install -y epel-release
                                #yum clean expire-cache
                                #yum -y update
                                [[ -e /usr/bin/salt-minion ]] || yum -y install salt-master salt-ssh salt-syndic salt-cloud salt-api salt-minion
                                curl -s "$demo_cfg_url" | tar xz  -C /srv/
                                cp /srv/salt/demo/files/mine.conf /etc/salt/minion.d/mine.conf
                                echo "$master_ip salt  salt-master-$cluster_nonce" >> /etc/hosts
                                (
                                echo "$ROOT_PW"
                                echo "$ROOT_PW"
                                ) | passwd --stdin root
                                rpm -q salt-minion && chkconfig salt-minion on && systemctl start salt-minion #Make sure salt is running.
                            params:
                                $master_ip: {get_attr: [cluster_master_port, fixed_ips, 0, ip_address]}
                                $ROOT_PW: {get_resource: root_pw}
                                $cluster_nonce: {get_resource: cluster_nonce}



outputs:
    master_ip:
        description: The IP of the Salt Master host.
        value: {get_attr: [cluster_master_port, fixed_ips, 0, ip_address]}
    root_password:
        description: The root PW for all hosts in the cluster
        value: {get_resource: root_pw}

```
