---
icon: lucide/server-cog
---

# AAP Installation

!!! tip
    Currently (Q2 2026), three different methods to install AAP are available:

    1. RPM (on RHEL)
    2. Containerized (with Podman on RHEL)
    3. Operator (on RedHat OpenShift)

    **The RPM-based method is deprecated**, use the *Containerized* method (or Operator).  

To *plan* the Automation Platform installation refer to the [Red Hat documentation](https://docs.redhat.com/en/documentation/red_hat_ansible_automation_platform/2.6/plan-assembly_overview_tested_deployment_models)!  
The following shows examples from a *containerized* installation.

The [containerized inventory growth topology](https://docs.redhat.com/en/documentation/red_hat_ansible_automation_platform/2.6/plan-ref_cont_a_env_a){:target="_blank".} installs all the components and services on a single machine, whereas the [containerized enterprise topology](https://docs.redhat.com/en/documentation/red_hat_ansible_automation_platform/2.6/plan-ref_cont_b_env_a){:target="_blank".} splits these components and services across multiple machines.

The Ansible Automation Platform is installed (on RHEL) via Ansible, it requires an `inventory` file which differs slightly for RPM and containerized installation

| RPM variable | Container variable | Description                                                                                      |
| ------------ | ------------------ | ------------------------------------------------------------------------------------------------ |
| `node_type`  | `receptor_type`    | The type of controller node (control or hybrid) or the type of execution node (execution or hop) |
| `peers`      | `receptor_peers`   | The list of node peers                                                                           |

??? example "Installation inventory example"

    The following shows an excerpt of the installation inventory for containers on multiple hosts:

    ```ini
    [automationcontroller]
    controller.example.com
    controller2.example.com

    [automationcontroller:vars]
    receptor_type=control
    receptor_peers=[]

    [execution_nodes]
    exec1.example.com
    exec2.example.com
    exec3.example.com
    hop1.example.com

    [local_nodes]
    exec1.example.com
    exec2.example.com

    [local_nodes:vars]
    receptor_peers=["controller.example.com","controller2.example.com"]

    [remote_nodes]
    exec3.example.com

    [remote_nodes:vars]
    receptor_peers=["hop1.example.com"]

    [hop_nodes]
    hop1.example.com

    [hop_nodes:vars]
    receptor_type=hop
    receptor_peers=["controller.example.com","controller2.example.com"]
    ```

The installer fails if the inventory file is misconfigured and will stop during its initial validation checks if it finds errors related to automation mesh, some errors might take several minutes before they eventually cause an installation failure:

* Hosts cannot belong to both the `automationcontroller` and `execution_nodes` host groups.
* A host cannot peer to a node that does not exist.
* A host cannot peer to itself.
* A host cannot have an inbound and an outbound connection to the same nodes.
* The `receptor_peers` variable cannot use a host group name and must provide a list of peers, even if that list only contains one peer.

Run the installation playbook:

```bash
ansible-playbook ansible.containerized_installer.install
```
