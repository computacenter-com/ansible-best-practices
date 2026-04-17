---
icon: lucide/rocket
---

# Executing playbooks

Ansible *content* can be executed differently, by default with the `ansible-playbook` utility, when Ansible (Core) is installed locally. The Ansible Control Node can also be contained in a Container image, the so-called *Execution Environments*, running those requires other tools like `ansible-navigator` or `ansible-runner`.

The most basic way:

```bash
ansible-playbook playbook.yml
```

Some useful command-line parameters when executing your playbook are the following

* `-C` or `--check` runs the playbook without making any modifications
* `-D` or `--diff` shows the differences when changing (small) files and templates
* `--step` runs one-step-at-a-time, you need to confirm each task before running
* `--list-tags` lists all available tags
* `--list-tasks` lists all tasks that would be executed

## Execute with Ansible Navigator

To ensure that your Ansible Content works, when running it locally during development **and** when running it in AAP or AWX later, it is advisable to execute it with the same execution environment.

AAP or AWX use container images to package the Python Runtime, Ansible installation, Python dependencies, collections and other custom components. The *ansible-playbook* command can't run container images, this is where the Navigator comes in.  

The *Ansible (Content) Navigator* is a command-line tool and a text-based user interface (TUI) for creating, reviewing, running and troubleshooting Ansible content, including inventories, playbooks, collections, documentation and container images (execution environments).  

Take a look at the [Installation section](installation.md#ansible-navigator) on how to install the utility and dependencies and the [Development section](../development/execution-environment.md#build-ee-image) on how to build a custom EE image.

Use the following minimal configuration for the Navigator and store it in your project root directory:

!!! tip inline end
    You can use `ansible-navigator` **without** Execution environments!  

    Add `#!yaml enabled: false` under the `execution-environment` key to use the local `ansible-core` binary.

```yaml title="ansible-navigator.yml"
---
ansible-navigator:
  execution-environment:
    image: ghcr.io/ansible-community/community-ee-base:latest # (1)!
    pull:
      policy: missing
  logging:
    level: warning
    file: logs/ansible-navigator.log
  mode: stdout # (2)!
  playbook-artifact:
    enable: true
    save-as: "logs/{playbook_status}-{playbook_name}-{time_stamp}.json" # (3)!
```

1. Specifies the name of the execution environment image to use, change this, if you want to use your own. The *pull policy* will download the image if it is not already present (this also means no updated images will be downloaded!).  
To build and use your own Execution Environment take a look at the section [Installation > Execution Environments](installation.md#execution-environments).
2. Specifies the user-interface mode, with `stdout` it will output to standard-out as with the usual `ansible-playbook` command. Use `interactive` to use the TUI. You can provide the CLI-parameter `-m` or `--mode` to overwrite the configuration.
3. Specifies the name for artifacts created from completed playbooks. For example, for a successful run of the `site.yml` playbook a log file like `logs/successful-site-2023-11-01T12:20:20.907856+00:00.json`. For failed runs it would be `logs/failed-site-2023-11-01T12:29:17.020432+00:00.json`. With the *replay* command, you now can observe output of previous playbook runs, e.g. `ansible-navigator replay logs/failed-site-2023-11-01T12\:29\:33.129179+00\:00.json`.

You can also use the Navigator configuration for **all** your projects, save it as a hidden file in your home directory (e.g. `~/.ansible-navigator.yml`).

??? tip "Create a more *complete* configuration with all *effective* settings?"

    To create a configuration file where defaults, CLI parameters, environment variables, and the settings file will be combined:

    ```bash
    ansible-navigator settings --effective --ee false > ansible-navigator.yml.sample # (1)!
    ```

    1. The parameter `--ee false` (do not use Execution Environments) is necessary, otherwise the Navigator will (try to) pull a default image.

        ```{ .bash .no-copy }
        $ ansible-navigator settings --effective > ansible-navigator.yml.sample
        Trying to pull ghcr.io/ansible/community-ansible-dev-tools:latest...
        Getting image source signatures
        Copying blob 080264fbf0bb [==========>---------------------------] 3.4MiB / 11.6MiB | 2.0 MiB/s
        ...
        ```

    !!! warning

        **Saving the file as `ansible-navigator.yml` directly does not work**, this will only create an empty file.  
        Remove the `.sample` extension or run `mv ansible-navigator.yml.sample ansible-navigator.yml`.

Use the [official Ansible Navigator Documentation](https://ansible.readthedocs.io/projects/navigator/settings/){:target="_blank"} for all other configuration options.

!!! warning
    With the configuration above, playbook artifacts (logs), as well as the Navigator Log-file, will be stored in a `logs` folder in your playbook directory. **Consider ignoring the folder from Git tracking.**

    ```bash title=".gitignore"
    logs/
    ```

    Take a look at the [Logging section](../development/logging.md#logging-with-ansible-navigator) for additional information.

Executing a playbook with the Navigator is as easy as before, just run it like this:

```bash
ansible-navigator run site.yml
```

Append any CLI-parameters (e.g. `-i inventory.ini`) that you are used to as when executing it with *ansible-playbook*.

!!! tip
    Using the *Interactive* mode (the *TUI*) is encouraged, try around!

The `ansible-navigator` commands map to `ansible` commands (prefix every Navigator command with `ansible-navigator`):

| Navigator command                        | Description                                                                                                        |
| ---------------------------------------- | ------------------------------------------------------------------------------------------------------------------ |
| <nobr>`exec -- ansible ...`</nobr>       | Runs Ansible *ad-hoc* commands.                                                                                    |
| `builder`                                | Builds new execution environments, the `ansible-builder` utility is installed with `ansible-navigator`.            |
| `config`                                 | Explore the current ansible configuration as with `ansible-config`.                                                |
| `doc`                                    | Explore the documentation for modules and plugins as with `ansible-doc`.                                           |
| `inventory`                              | Inspect the inventory and browser groups and hosts.                                                                |
| `lint`                                   | Runs best-practice checker, `ansible-lint` needs to be installed locally or in the selected execution-environment. |
| `run`                                    | Runs Playbooks.                                                                                                    |
| <nobr>`exec -- ansible-test ...`</nobr>  | Executes sanity, unit and integration tests for Collections.                                                       |
| <nobr>`exec -- ansible-vault ...`</nobr> | Runs utility to encrypt or decrypt Ansible content.                                                                |

## Execute with Ansible Runner

!!! tip
    The *Ansible Navigator* is easier to use than the `ansible-runner`, use this one for creating, reviewing, running and troubleshooting Ansible content, including inventories, playbooks, collections, documentation and execution environments.  

Ansible Runner is a tool and python library to provide a stable and consistent interface abstraction to Ansible, it used inside an Execution Environment for running the `ansible` or `ansible-playbook` CLI utilities and gather the output from those.  
Still, it *can* be used standalone.

To use Ansible from the container image with `ansible-runner`, e.g. for an ad hoc command (*setup* module) against localhost, use the following:

```bash
ansible-runner run --container-image demo/openshift-ee /tmp -m setup --hosts localhost
```

Most parameters should be self-explanatory:

* *run* - Run ansible-runner in the foreground
* *--container-image demo/openshift* - Container image to use when running an ansible task
* */tmp* - base directory containing the ansible-runner metadata (project, inventory, env, etc)
* *-m setup* - Module to execute
* *--hosts localhost* - set of hosts to execute against (here only localhost)

The output looks like expected:

``` { .bash .no-copy }
$ ansible-runner run --container-image demo/openshift-ee /tmp -m setup --hosts localhost
[WARNING]: No inventory was parsed, only implicit localhost is available
localhost | SUCCESS => {
    "ansible_facts": {
        "ansible_all_ipv4_addresses": [
            "192.168.178.114",
            "172.17.0.1"
        ],
        "ansible_all_ipv6_addresses": [
            "2001:9e8:4a14:2401:a00:27ff:febf:4207",
            "fe80::a00:27ff:febf:4207",
            "fe80::42:9eff:fef9:df59"
        ],
        "ansible_apparmor": {
            "status": "enabled"
        },
        "ansible_architecture": "x86_64",
        "ansible_bios_date": "12/01/2006",
        "ansible_bios_vendor": "innotek GmbH",
        "ansible_bios_version": "VirtualBox",
        "ansible_board_asset_tag": "NA",
        "ansible_board_name": "VirtualBox",
        "ansible_board_serial": "NA",
        "ansible_board_vendor": "Oracle Corporation",
        ...
```

To execute a playbook against a given inventory, use the `-p` and `--inventory` option:

```bash
ansible-runner run --container-image demo/openshift-ee /tmp -p playbook.yml --inventory inventory.yml
```
