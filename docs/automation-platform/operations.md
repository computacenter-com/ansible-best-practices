---
icon: lucide/id-card-lanyard
---

# Managing & operating AAP

To *maintain* the Ansible Automation Platform it is not only necessary to start/stop, backup or extend the platform. Operating the AAP must be done on different domains, from technology, to people and processes (in no particular order!).

The [Red Hat EMEA Ansible Launch Team](https://ansible-ops-model.gitlab.io/#about-us){:target="_blank"} created a good practice based [Operational Model for AAP](https://ansible-ops-model.gitlab.io/){:target="_blank"}, for people who want inspiration for how you can run a central automation platform based on Ansible Automation Platform.  
The model, which covers **people, process, technology, service management and strategy** is divided between three different advancement levels, from [MVP](https://ansible-ops-model.gitlab.io/mvp/){:target="_blank"} over [2.0](https://ansible-ops-model.gitlab.io/twozero/){:target="_blank"} to [Advanced](https://ansible-ops-model.gitlab.io/advanced/){:target="_blank"}.

<figure markdown="span">
  ![AAP Operational Model](https://gitlab.com/ansible-ops-model/ansible-ops-model.gitlab.io/-/raw/8cf1e7e7e6457994a7526df486e4b1b106917e9f/assets/images/aap-operational-model.jpg)
</figure>

## Start/stop/restart AAP

Containerized deployments on RHEL configure Ansible Automation Platform services to automatically start at boot using the username that was used to perform the installation. To identify the user, use the `loginctl list-users` command on a machine that contains Ansible Automation Platform components:

```{ .bash .no-copy }
[admin@controller ~]$ loginctl list-users
 UID USER    LINGER STATE
1000 admin no     active
1001 aap   yes    lingering
```

Here, the AAP was installed under the `aap` user, all SystemD unit files are located under `~/.config/systemd/user/`

```{ .bash .no-copy }
[aap@controller ~]$ ls -1F ~/.config/systemd/user/
automation-controller-rsyslog.service
automation-controller-task.service
automation-controller-web.service
default.target.wants/
podman.service.d/
receptor.service
redis-tcp.service
redis-unix.service
sockets.target.wants/
```

The `podman ps` command shows information about running containers. The container names match their corresponding systemd services:

```{ .bash .no-copy }
[aap@controller ~]$ podman ps
CONTAINER ID  IMAGE                        ...  NAMES
3fe9219a61fe  .../redis-6:latest           ...  redis-tcp
df5f649386ec  .../redis-6:latest           ...  redis-unix
f54c38f1158e  .../receptor-rhel8:latest    ...  receptor
2c6719357132  .../controller-rhel8:latest  ...  automation-controller-rsyslog
10149814aae8  .../controller-rhel8:latest  ...  automation-controller-task
d5c2667fa88b  .../controller-rhel8:latest  ...  automation-controller-web
```

Use the `systemctl --user` command to start/stop/restart the services:

```bash
systemctl --user restart automation-controller-web.service
```

??? example

    ```{ .bash .no-copy }
    [aap@controller ~]$ systemctl --user status automation-controller-web.service
    ● automation-controller-web.service - Podman automation-controller-web.service
        Loaded: loaded (/home/aap/.config/systemd/user/automation-controller-web.service; enabled; preset: disabled)
        Active: active (running) since Tue 2026-01-13 14:05:25 UTC; 7h ago
          Docs: man:podman-generate-systemd(1)
        Process: 1232 ExecStart=/usr/bin/podman start automation-controller-web (code=exited, status=0/SUCCESS)
      Main PID: 1385 (conmon)
          Tasks: 1 (limit: 22676)
        Memory: 15.9M
            CPU: 1.298s
    ...
    ```

!!! warning

    Ensure that you log in and run the `systemctl --user` command as the user who has lingering services. Logging in as that user correctly sets the XDG_RUNTIME_DIR variable.  
    If you *become* the user who has lingering services by using the `sudo` or `su` command, then you'll need to set the `XDG_RUNTIME_DIR` variable:

    ```bash
    export XDG_RUNTIME_DIR=/run/user/$(id -u)
    ```

## Configuration & Log files

The installer places configuration files on each machine that contains an Ansible Automation Platform component or service. These files exist in the `~/aap` directory of the user who performed the installation and are mounted into the relevant containers at runtime.  
Perhaps the most important of these files for the automation controller application is the `/etc/tower/settings.py` file, which specifies the locations for job output, project storage, and other directories. If necessary, edit the `~/aap/controller/etc/settings.py` file on the container host to change any settings, and then restart the `automation-controller-web` container.

```{ .bash .no-copy }
[aap@hcontroller~]$ podman inspect automation-controller-web
...
  "HostConfig": {
       "Binds": [
            "receptor_run:/run/receptor:U,rw,rprivate,nosuid,nodev,rbind",
            "redis_run:/run/redis:U,rw,rprivate,nosuid,nodev,rbind",
...
            "/home/aap/aap/controller/etc/tower.key:/etc/tower/tower.key:ro,rprivate,rbind",
            "/home/aap/aap/controller/data/logs:/var/log/tower:rw,rprivate,rbind",
            "/home/aap/aap/controller/data/rsyslog:/var/lib/awx/rsyslog:rw,rprivate,rbind",
            "/home/aap/aap/controller/etc/conf.d/redis.py:/etc/tower/conf.d/redis.py:ro,rprivate,rbind",
            "/home/aap/aap/controller/etc/launch_awx_task.sh:/usr/bin/launch_awx_task.sh:ro,rprivate,rbind",
            "/home/aap/aap/controller/etc/settings.py:/etc/tower/settings.py:ro,rprivate,rbind",
...
```

The AAP web application log files are written to the `/var/log/tower` directory, which is mounted from the `~/aap/controller/data/logs` directory on the machine that hosts automation controller, e.g.

* `/var/log/tower/tower.log` - The main log file
* `/var/log/tower/task_system.log` - Contains information about tasks that automation controller runs in the background, such as adding cluster instances and logs related to information gathering as well as processing for analytics.

Also, use the Podman container logs. In this example, the connection to Postgres database failed:

```{ .bash .no-copy }
[aap@controller ~]$ podman logs automation-controller-web
...
  File "/var/lib/awx/venv/awx/lib64/python3.11/site-packages/django/db/backends/postgresql/base.py", line 275, in get_new_connection
    connection = self.Database.connect(**conn_params)
                 ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  File "/var/lib/awx/venv/awx/lib64/python3.11/site-packages/psycopg/connection.py", line 748, in connect
    raise last_ex.with_traceback(None)
psycopg.OperationalError: connection failed: server closed the connection unexpectedly
        This probably means the server terminated abnormally
        before or while processing the request.
...
```

## Update admin password

The password for the built-in admin account is initially set during the Ansible Automation Platform deployment.  
A new password can be set from the CLI on the Automation Gateway using the `aap-gateway-manage`. As the user who installed Ansible Automation Platform, use the `podman exec` command to connect to the **automation-gateway container**.

```bash
podman exec -it automation-gateway /bin/bash
```

Now, set a new admin password:

```bash
aap-gateway-manage changepassword admin
```

??? example

    ```{ .bash .no-copy }
    [aap@gateway ~]$ podman exec -it automation-gateway /bin/bash
    bash-4.4$ aap-gateway-manage changepassword admin
    Changing password for user 'admin'
    Password:
    Password (again):
    Password changed successfully for user 'admin'
    ```

Alternatively, use the `aap-gateway-manage` command to create an new Ansible Automation Platform superuser:

```bash
aap-gateway-manage createsuperuser
```

## Add/remove nodes from AAP

To add additional nodes to AAP, take a look at the [installation section](installation.md#aap-installation).

Removing nodes from the Automation Platform differs from RPM or containerized installation.

=== "Containerized"

    For containerized installations, connect to any of the automation controller hosts. These hosts run the automation-controller-*` containers. Connect to an automation-controller-* container via `podman exec` and then use the `awx-manage deprovision_instance` command to remove a node:

    ```{ .bash .no-copy }
    [aap@controller ~]$ podman exec -it automation-controller-task /bin/bash
    bash-4.4$ awx-manage deprovision_instance --hostname=exec5.example.com
    ```

    !!! tip

        Ensure that you log in and run the podman command as the user who has lingering services (identified with the `loginctl list-users` command). Logging in as that user correctly sets the `XDG_RUNTIME_DIR` variable.

        If you become the user who has lingering services by using the sudo or su command, then you can set the XDG_RUNTIME_DIR variable with the following command:

        ```bash
        export XDG_RUNTIME_DIR=/run/user/$(id -u)
        ```

=== "RPM"

    To remove nodes from the Automation Platform, add the `node_state=deprovision` variable to the installation inventory:

    ```ini hl_lines="4 8"
    [automationcontroller]
    controller.example.com
    controller2.example.com
    controller3.example.com node_state=deprovision

    [execution_nodes]
    exec1.example.com
    exec5.example.com node_state=deprovision
    ```

    !!! warning
        You cannot use `node_state=deprovision` with the **first entry** in the `[automationcontroller]` section because the installer needs at least one operational controller.  
        **The installer uses the first entry to launch the remaining installation and configuration.**  

        !!! success
            Just move the controller host (which should be deprovisioned) from the first to a different position in the `[automationcontroller]` section.

    Now, run the `setup.sh` script:

    ```bash
    ./setup.sh -i inventory
    ```

## Backup & Restore

The ability to manually back up and restore a Red Hat Ansible Automation Platform installation is integrated into installation software.  
The procedure to back up Ansible Automation Platform uses the same files and inventory file that you used to perform an installation:

* RPM installations use the `setup.sh` script with the `-b` option to perform a backup. Run the setup.sh script as the root user.
* Containerized installations use the `ansible.containerized_installer.backup` playbook.

!!! info
    **You need the inventory file which was used during the installation!**

The `ansible.containerized_installer.backup` playbook creates a `backups` directory and populates that directory with archive files based on your installation. Ensure that you have enough free space available before running the playbook.

Change into the AAP installation directory and run the playbook:

```bash
ansible-playbook ansible.containerized_installer.backup
```

??? example "Example content"

    ```{ .bash .no-copy }
    [admin@bastion installer]$ ls -1 backups/
    controller_controller.example.com.tar.gz
    controller_controller2.example.com.tar.gz
    eda_eda.example.com.tar.gz
    gateway_aap.example.com.tar.gz
    hub_hub.example.com.tar.gz
    hub_hub2.example.com.tar.gz
    postgresql_db.example.com.tar.gz
    receptor_controller.example.com.tar.gz
    receptor_controller2.example.com.tar.gz
    receptor_exec1.example.com.tar.gz
    receptor_exec2.example.com.tar.gz
    receptor_exec3.example.com.tar.gz
    receptor_hop1.example.com.tar.gz
    redis_aap.example.com.tar.gz
    redis_controller.example.com.tar.gz
    redis_controller2.example.com.tar.gz
    redis_eda.example.com.tar.gz
    redis_hub.example.com.tar.gz
    redis_hub2.example.com.tar.gz
    ```

To restore, use the installation directory (with the `inventory` file) and ensure a `backups` folder exists which contains archive files. Run the ` ansible.containerized_installer.restore`  playbook:

```bash
ansible-playbook ansible.containerized_installer.restore
```

!!! info
    The restore playbook can take more than an hour to complete!

## Configuration as Code

Running or operating the Automation Platform at scale can be challenging, when dealing with large, complex environments. You often need to **replicate configurations** between environments or sites.  
Database replication to copy data from one environment to another (for instance, importing data from one Ansible Automation Platform site to another) is one approach. This approach can require a dedicated infrastructure, specialized teams to handle the process, and complex procedures for switching the active site. This design can affect consistency across multiple environments or sites.  
Another possibility is treating the AAP configuration **as code** and using Ansible automation to automate the AAP itself.

The [Red Hat Communities of Practice](https://redhat-cop.github.io/){:target="_blank"} created many useful collections, roles and playbooks for AAP configuration as code.

As there are new components (*Automation Gateway*) and new APIs with Ansible Automation Platform 2.5+, automating AAP requires different collections.

### AWX & AAP <= 2.4

For automating AWX and Automation Platform 2.4 and earlier, use the [Controller Configuration Collection](https://galaxy.ansible.com/ui/repo/published/infra/controller_configuration/){:target="_blank"}.

```bash
ansible-galaxy collection install infra.controller_configuration
```

### AAP 2.5+

For automating Automation Platform 2.5 and later, use the [AAP Configuration Collection](https://galaxy.ansible.com/ui/repo/published/infra/aap_configuration/){:target="_blank"}.

```bash
ansible-galaxy collection install infra.aap_configuration
```

## Extended configuration and helper roles

The [AAP Configuration Extended Collection](https://galaxy.ansible.com/ui/repo/published/infra/aap_configuration_extended/){:target="_blank"} contains some very useful roles and playbooks for automating **existing and manually configured** AAP instances, as well as supporting with the migration between AAP 2.4 and 2.5.  

For example:

* [infra.controller_configuration.filetree_create](https://galaxy.ansible.com/ui/repo/published/infra/aap_configuration_extended/content/role/filetree_create/){:target="_blank"} - creates a filetree with YAML files of the existing AAP configuration
* [infra.controller_configuration.upgrade_config](https://galaxy.ansible.com/ui/repo/published/infra/aap_configuration_extended/content/role/upgrade_config/){:target="_blank"} - converts the configuration files used for AAP <= 2.4 CaC collections to the new format supported by the AAP >= 2.5 CaC collections.

```bash
ansible-galaxy collection install infra.aap_configuration_extended
```
