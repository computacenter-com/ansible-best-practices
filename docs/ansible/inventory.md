---
icon: lucide/server
---

# Inventory

An *inventory* is a list of managed nodes, or hosts, that Ansible deploys and configures. The inventory can either be static or dynamic.  
You can use group names to classify hosts and to decide which hosts you are controlling following these criteria:

* **What** - An application, stack, or microservice (e.g. database servers, web servers, and so on).
* **Where** - A datacenter or region, to talk to local DNS, storage, and so on (e.g., east, west).
* **When** - The development stage, to avoid testing on production resources (e.g. prod, test).

!!! tip
    To *verify* that Ansible has properly read an inventory source, `ansible-inventory --graph` can be used. It prints the structure of hosts and groups and is especially useful for *dynamic inventories*.

    ```bash
    @all:
      |--@ungrouped:
      |--@webapp:
      |  |--@webserver:
      |  |  |--web01
      |  |  |--web02
      |  |--@database:
      |  |  |--db01
      |--@backup:
      |  |--backup01
    ```

## Static inventory

The simplest inventory is a single *static* file that contains a list of hosts and groups. Connections are defined more precisely using variables. This approach makes getting started particularly easy.  
A `.ini` inventory file for example might look like this:

```ini title="inventory.ini"
[control]
wsl ansible_host=localhost ansible_connection=local

[target]
rocky8 ansible_host=192.168.43.77
ubuntu ansible_host=192.168.45.68

[target:vars]
ansible_ssh_private_key_file=~/.ssh/id_for_ansible.pem
```

The same inventory can be expressed in the YAML format.

```yaml title="inventory.yml"
control:
  hosts:
    wsl:
      ansible_connection: local
      ansible_host: localhost

target:
  hosts:
    rocky8:
      ansible_host: 192.168.43.77
    ubuntu:
      ansible_host: 192.168.45.68
  vars:
    ansible_ssh_private_key_file: ~/.ssh/id_for_ansible.pem
```

!!! tip
    Prefer the YAML format.

### Convert INI to YAML

The most common format for the *Ansible Inventory* is the `.ini` format, but sometimes you might need the inventory file in the *YAML* format. You can convert your existing inventory to the YAML format with the `ansible-inventory` utility.

```bash
ansible-inventory -i inventory.ini -y --list > inventory.yml
```

### Inventory alias

The `inventory_hostname` is the unique identifier for a host in Ansible, but it does **not** need to be the actual (resolvable) hostname used for connecting to the target.  
You can create a custom *alias* which will be shown in the Ansible output.

<div class="grid" markdown>

```yaml hl_lines="6"
--- # (1)!
all:
  children:
    managed_nodes:
      hosts:
        instance1: # (2)!
          ansible_host: rhel9-node1 # (3)!
      vars: # (4)!
        ansible_ssh_private_key_file: ~/.ssh/id_for_ansible.pem
        ansible_user: ansible
        ansible_ssh_pipelining: true
```

1. The same inventory in `.ini` format:

    ```ini
    [managed_nodes]
    instance1 ansible_host=rhel9-node1

    [managed_nodes:vars]
    ansible_ssh_private_key_file=~/.ssh/id_for_ansible.pem
    ansible_user=ansible
    ansible_ssh_pipelining=true
    ```

2. The *alias*, corresponds to the variable `inventory_hostname` and **is shown in the Ansible output**.
3. Specifies the **resolvable name** (or ideally the IP) of the host to connect to.

    ```{ .ansible-output .no-copy }
    TASK [The actual value used for the connection] **********************
    ok: [instance1] =>
        ansible_host: rhel9-node1
    ```

4. A couple of [behavioral connection parameters](https://docs.ansible.com/projects/ansible/latest/inventory_guide/intro_inventory.html#connecting-to-hosts-behavioral-inventory-parameters){:target="_blank"} for all `managed_nodes` (group variables).

```{ .ansible-output .no-copy }
TASK [Gathering Facts] ***********************************************
ok: [instance1]

TASK [The used 'alias', shown as the target name in the output] ******
ok: [instance1] =>
    inventory_hostname: instance1

TASK [The actual value used for the connection] **********************
ok: [instance1] =>
    ansible_host: rhel9-node1

TASK [What the host itself reports as its FQDN] **********************
ok: [instance1] =>
    ansible_facts['fqdn']: rhel9-node1.example.com
```

</div>

!!! success
    Although the connection to the host is done via the actual hostname (`rhel9-node1`), the output shows the alias (`instance1`).

An additional example can be be found in the [No inventory section](inventory.md#no-inventory) where an alias is used for localhost to have a cleaner output when connecting to a network/API endpoint.

## Dynamic inventory

If your Ansible inventory fluctuates over time, with hosts spinning up and shutting down in response to business demands, the static inventory solutions described in [How to build your inventory](https://docs.ansible.com/ansible/latest/inventory_guide/intro_inventory.html){:target="_blank"} will not serve your needs. You may need to track hosts from multiple sources: cloud providers, LDAP, Cobbler, and/or enterprise CMDB systems.

There are already loads of [inventory plugins](https://docs.ansible.com/ansible/latest/collections/index_inventory.html){:target="_blank"} available, for example:

* [amazon.aws.aws_ec2](https://docs.ansible.com/ansible/latest/collections/amazon/aws/aws_ec2_inventory.html){:target="_blank"}
* [community.proxmox.proxmox](https://docs.ansible.com/ansible/latest/collections/community/proxmox/proxmox_inventory.html){:target="_blank"}
* [netbox.netbox.nb_inventory](https://docs.ansible.com/ansible/latest/collections/netbox/netbox/nb_inventory_inventory.html){:target="_blank"}
* [vmware.vmware.vms](https://docs.ansible.com/ansible/latest/collections/vmware/vmware/vms_inventory.html){:target="_blank"}

### Custom dynamic inventory

In case no suitable inventory plugin exists, you can easily write your own. Take a look at the [Ansible Development - Extending](../development/extending.md#inventory-plugins) section for additional information.

## In-Memory Inventory

Normally Ansible requires an inventory file, to know which machines it is meant to operate on.

This is typically a manual process but can be greatly improved by using a dynamic inventory to pull inventory information from other systems.

Suppose, however, you needed to create *X* number of instances, which are transient in nature and had no existing details available to populate an inventory file for Ansible to utilise. If *X* is a small number, you could easily hand-craft the inventory file while the playbook already runs.

Use the [`add_host` module](https://docs.ansible.com/ansible/latest/collections/ansible/builtin/add_host_module.html#ansible-collections-ansible-builtin-add-host-module){:target="_blank"}, which makes use of Ansible's ability to populate an *in-memory inventory* with information it generates while creating new instances.

Take a look at the following example, the first *play* creates a couple of Containers and adds them to a new group. The seconds plays targets this new group and connects to the newly created Containers.

```yaml
---
- name: Add hosts to additional groups
  hosts: localhost
  connection: local
  gather_facts: false
  vars:
    container_list:
      - node1
      - node2
      - node3
  tasks:
    - name: Start managed node containers
      containers.podman.podman_container:
        name: "{{ item }}"
        image: docker.io/timgrt/rockylinux8-ansible:latest
        hostname: "{{ item }}.example.com"
        stop_signal: 15
        state: started
      loop: "{{ container_list }}"

    - name: Add container to new group
      ansible.builtin.add_host:
        name: "{{ item }}" # (1)!
        groups: managed_node_containers # (2)!
        ansible_connection: podman # (3)!
        ansible_python_interpreter: /usr/libexec/platform-python # (4)!
        stage: test # (5)!
      loop: "{{ container_list }}"

- name: Run tasks on containers created in previous play
  hosts: managed_node_containers
  tasks:
    - name: Output stage variable
      ansible.builtin.debug:
        msg: "{{ stage }}"
```

1. Every container instance is added by looping the variable `container_list`. As the `name` parameter must be a string a loop is necessary.
2. This is the name of the new group! It is targeted in the second play. The `groups` parameter can be a list of multiple group names.
3. These are variables needed to connect to the new instances. As they are Podman containers the *podman* connection plugin is used.
4. The Python interpreter which is used in the new instances. Not always necessary, as normally Ansible discovers the interpreter pretty reliable.
5. This is a custom variable for all new instances. You can add more variables here if necessary.

??? example "Playbook output"

    ```{ .ansible-output .no-copy }
    $ ansible-playbook in-memory-inventory.yml

    PLAY [Add hosts to additional groups] *******************************************************************************************************************************

    TASK [Start managed node containers] ********************************************************************************************************************************
    ok: [localhost] => (item=node1)
    ok: [localhost] => (item=node2)
    ok: [localhost] => (item=node3)

    TASK [Add container to new group] ***********************************************************************************************************************************
    changed: [localhost] => (item=node1)
    changed: [localhost] => (item=node2)
    changed: [localhost] => (item=node3)

    PLAY [Run tasks on containers created in previous play] *************************************************************************************************************

    TASK [Gathering Facts] **********************************************************************************************************************************************
    ok: [node2]
    ok: [node1]
    ok: [node3]

    TASK [Output stage variable] ****************************************************************************************************************************************
    ok: [node1] =>
        msg: test
    ok: [node2] =>
        msg: test
    ok: [node3] =>
        msg: test
    ```

## No inventory

An inventory is not always necessary, depending on your use-case and the modules used.  
For example, network modules do not run on the managed nodes (as, in most cases, they do not have a usable Python interpreter), they are executed on the Ansible control node. Therefore, you'll need to use the `local` connection method running against `localhost`. The module itself handles the connection, mostly you'll need to provide the endpoint, username, password, certificate validation, etc. in every task (take a look at the [module_defaults section](../ansible/playbook.md#module-defaults) to simplify this).  

Still, it can be useful to provide a small inventory to have a ***named* target for a cleaner output**.

!!! quote ""

    <div class="grid" markdown>

    !!! success "Named target"

        The following inventory creates an [*alias*](inventory.md#inventory-alias) for `localhost` which will be shown in the playbook output:

        ```ini title="inventory.ini"
        [apic]
        sandboxapicdc.cisco.com ansible_host=localhost ansible_connection=local
        ```

        The playbook targets the `apic` group:

        ```yaml title="aci_automation.yml"
        - name: Automate Cisco ACI
          hosts: apic
          gather_facts: false # (1)!
          roles:
            - aci_automation
        ```

        1. Fact gathering can be disabled as it would get data from localhost, which is most likely not used.

        ```{ .ansible-output .no-copy }
        $ ansible-playbook -i inventory.ini aci_automation.yml

        PLAY [Automate Cisco ACI] *******************************************************************************************

        TASK [aci-automation : Create tenant] *******************************************************************************
        changed: [sandboxapicdc.cisco.com]

        ...
        ```

        **The output shows the name of the targeted APIC, which better indicates where the changes are done!**

    !!! failure "Showing localhost only"

        The target and connection method can be provided in the playbook directly:

        ```yaml title="aci_automation.yml"
        - name: Automate Cisco ACI
          hosts: localhost
          connection: local
          gather_facts: false # (1)!
          roles:
            - aci_automation
        ```

        1. Fact gathering can be disabled as it would get data from localhost, which is most likely not used.

        Running this does not require an inventory file:

        ```{ .ansible-output .no-copy }
        $ ansible-playbook aci_automation.yml
        [WARNING]: No inventory was parsed, only implicit localhost is available
        [WARNING]: provided hosts list is empty, only localhost is available. Note that the implicit localhost does not match 'all'

        PLAY [Automate Cisco ACI] *******************************************************************************************

        TASK [aci-automation : Create tenant] *******************************************************************************
        changed: [localhost]

        ...
        ```

        **The output shows `localhost` as the target, although that is not the actual target...**  
        Additionally, **warnings are shown** when not providing an inventory **and** running against localhost. Take a look at the [configuration section](../ansible/project.md#silence-warnings-about-no-inventory-or-localhost) on how to deal with those.

    </div>

## Configuration file

Configure your inventory file(s) in the `ansible.cfg`, now you do not have to provide it with `--inventory`/`-i` anymore.  
You can provide multiple files as a comma-separated string, mixes of static and dynamic inventory files and scripts are also possible.

```ini title="ansible.cfg"
[defaults]
inventory = inventory.ini,dev.aws_ec2.yml,netbox_inventory.yml
```

## Inventory variables

Variables *can* be assigned to every host and/or group in the inventory file *directly*, but this makes the file not very readable with a growing number of hosts, groups and variables.

!!! success
    Use the `group_vars` and `host_vars` folder.

Do not create *files* for the groups or hosts (e.g. `group_vars/web.yml` or `host_vars/node1.yml`), but use **folders** for hosts and groups instead.  
Underneath these folders, you can create multiple *variables*-files which are **all** loaded by the [host_group_vars plugin](https://docs.ansible.com/ansible/latest/collections/ansible/builtin/host_group_vars_vars.html){:target="_blank"}.

```bash
host_vars
├── kafka_node1
│   ├── network.yml
│   └── dns.yml
├── kafka_node2
│   └── network.yml
└── kafka_node3
    └── network.yml
group_vars/
├── all
│   ├── dns.yml
│   └── vault.yml
└── kafka_servers
    └── topics.yml
```
