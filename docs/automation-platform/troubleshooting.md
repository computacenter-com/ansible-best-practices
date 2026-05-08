---
icon: lucide/server-crash
---

# Troubleshooting AAP

Red Hat Ansible Automation Platform is composed of many components and services. Sometime things go wrong and need to be fixed.  
The following steps help you to identify underlying problems.

For a basic overview on how to identify the running AAP containers, take a look at [Managing AAP in the Operations sections](operations.md#startstoprestart-aap)

## Listing nodes and instance groups

Use the `awx-manage list_instances` command from within any of the `automation-controller-*` containers, such as the `automation-controller-task` container, to list all the instances in the mesh. The command shows the status of each node.

```bash
podman exec -it automation-controller-task /bin/bash
```

In the following example, the `controller2.example.com node` displays the DISABLED status:

```{ .bash .no-copy }
[devops@controller ~]$ podman exec -it automation-controller-task /bin/bash
bash-4.4$ awx-manage list_instances
...output omitted...
[controlplane capacity=16]
    [DISABLED] controller2.example.com capacity=0 node_type=control version=4.7.6 heartbeat="2026-01-14 21:48:34"
    controller.example.com capacity=16 node_type=control version=4.7.6 heartbeat="2026-01-14 21:48:35"

[default capacity=64]
    [DISABLED] controller2.example.com capacity=0 node_type=control version=4.7.6 heartbeat="2026-01-14 21:48:34"
    controller.example.com capacity=16 node_type=control version=4.7.6 heartbeat="2026-01-14 21:48:35"
    exec1.example.com capacity=16 node_type=execution version=ansible-runner-2.4.2 heartbeat="2026-01-14 21:48:25"
    exec2.example.com capacity=16 node_type=execution version=ansible-runner-2.4.2 heartbeat="2026-01-14 21:48:25"
    exec3.example.com capacity=16 node_type=execution version=ansible-runner-2.4.2 heartbeat="2026-01-14 21:48:25"

[executionplane capacity=48]
    exec1.example.com capacity=16 node_type=execution version=ansible-runner-2.4.2 heartbeat="2026-01-14 21:48:25"
    exec2.example.com capacity=16 node_type=execution version=ansible-runner-2.4.2 heartbeat="2026-01-14 21:48:25"
    exec3.example.com capacity=16 node_type=execution version=ansible-runner-2.4.2 heartbeat="2026-01-14 21:48:25"

[ungrouped capacity=0]
    hop1.example.com node_type=hop heartbeat="2026-01-14 21:48:20"
```

## Monitoring Automation Mesh communication

Use the `receptorctl` command to test communication on the automation mesh. You can run this command from `automation-controller-web` containers.  

```bash
podman exec -it automation-controller-web /bin/bash
```

The command provides several subcommands, including:

* `receptorctl status` retrieves the status of the entire automation mesh.
* `receptorctl ping` tests connectivity between the current node and another node in the automation mesh.
* `receptorctl traceroute` determines the route and latency of communication on the automation mesh between the current node and another node.

??? example "Receptor communication example"

    ```{ .bash .no-copy }
    [aap@controller ~]$ podman exec -it automation-controller-web /bin/bash
    bash-4.4$ /var/lib/awx/venv/awx/bin/receptorctl --socket /run/receptor/receptor.sock status
    Node ID: controller.example.com
    Version: 1.6.2
    System CPU Count: 1
    System Memory MiB: 3659

    Connection                  Cost
    exec1.example.com           1
    controller2.example.com     1
    hop1.example.com            1
    exec2.example.com           1

    Known Node                  Known Connections
    controller.example.com      controller2.example.com: 1 exec1.example.com: 1 exec2.example.com: 1 hop1.example.com: 1
    controller2.example.com     controller.example.com: 1 exec1.example.com: 1 exec2.example.com: 1 hop1.example.com: 1
    exec1.example.com           controller.example.com: 1 controller2.example.com: 1
    exec2.example.com           controller.example.com: 1 controller2.example.com: 1
    exec3.example.com           hop1.example.com: 1
    hop1.example.com            controller.example.com: 1 controller2.example.com: 1 exec3.example.com: 1

    Route                       Via
    controller2.example.com     controller2.example.com
    exec1.example.com           exec1.example.com
    exec2.example.com           exec2.example.com
    exec3.example.com           hop1.example.com
    hop1.example.com            hop1.example.com

    Node                        Service   Type       Last Seen             ...
    controller.example.com      control   StreamTLS  2026-01-16 15:09:48   ...
    controller2.example.com     control   StreamTLS  2026-01-16 15:08:53   ...
    hop1.example.com            control   StreamTLS  2026-01-16 15:09:33   ...
    exec1.example.com           control   StreamTLS  2026-01-16 15:09:35   ...
    exec3.example.com           control   StreamTLS  2026-01-16 15:09:35   ...
    exec2.example.com           control   StreamTLS  2026-01-16 15:09:40   ...

    Node                        Secure Work Types
    controller.example.com      local, kubernetes-runtime-auth, kubernetes-...
    controller2.example.com     local, kubernetes-runtime-auth, kubernetes-...
    exec1.example.com           ansible-runner
    exec3.example.com           ansible-runner
    exec2.example.com           ansible-runner
    ```

Use the `ping` subcommand to test connectivity between the current host and another host.

```bash
/var/lib/awx/venv/awx/bin/receptorctl --socket /run/receptor/receptor.sock ping exec2.example.com
```

Example output:

```{ .bash .no-copy }
bash-4.4$ /var/lib/awx/venv/awx/bin/receptorctl --socket /run/receptor/receptor.sock ping exec2.example.com
Reply from exec2.example.com in 800.475µs
Reply from exec2.example.com in 560.704µs
Reply from exec2.example.com in 645.446µs
Reply from exec2.example.com in 577.664µs
```

Use the `traceroute` subcommand to view the route between nodes. Here, the `controller.example.com` node connects to `exec3.example.com` node through the `hop1.example.com` node:

```{ .bash .no-copy }
bash-4.4$ /var/lib/awx/venv/awx/bin/receptorctl --socket /run/receptor/receptor.sock traceroute exec3.example.com
0: controller.example.com in 786.099µs
1: hop1.example.com in 1.104271ms
2: exec3.example.com in 1.059081ms
```
