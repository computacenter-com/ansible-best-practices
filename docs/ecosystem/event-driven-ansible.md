---
icon: lucide/square-activity
---
# Event-Driven Ansible

Event-Driven Ansible connects sources of events with corresponding actions via rules.
Ansible Rulebooks define the event source and explain—in the form of conditional “if-this-then-that” instructions—the action to take when the event occurs, using a decision framework that was built using Drools.  
Based on the designed rulebook, EDA recognizes the specified event, matches it with the appropriate action, and automatically executes it. Rulebooks are written in YAML and are used like traditional Ansible Playbooks.

!!! info
    **This section focuses on the CLI variant with the `ansible-rulebook` utility!**  
    Event-Driven Ansible is included in the [Ansible Automation Platform, take a look at that section for additional information](../automation-platform/index.md){ data-preview }.

## Installation

Event-Driven Ansible requires the following:

* Python >=3.9,<=3.13
* `ansible-core`
* `ansible-runner`
* `ansible-rulebook`
* Java development kit >= 17

Especially because of the required Java installation (used by the underlying Drools engine), use the provided Container image:

```bash
podman pull quay.io/ansible/ansible-rulebook:latest
```

## Rulebook

!!! abstract "EDA vs. Ansible"
    Event-Driven Ansible &rarr; **Rule**books  
    *Classic* Ansible &rarr; **Play**books

A rulebook is comprised of three main components:

* **Sources** define which event source we will use. Source plugins are installed through collections.
* **Rules** define conditionals that will try to match output from the event source. Should the condition be met, then we can trigger an action.
* **Actions** trigger what you need to happen should a condition be met.

```yaml hl_lines="3 19 22 27"
- name: Listen for events in Dynatrace tenant
  hosts: all # (1)!
  sources:
    - name: Dynatrace sgb38850
      dynatrace.event_driven_ansible.dt_esa_api: # (2)!
        dt_api_host: "https://sgb38850.live.dynatrace.com"
        dt_api_token: !vault | # (3)!
          $ANSIBLE_VAULT;1.1;AES256
          37613335303635343263383639386530636636323236376639613465323238626665323063393861
          3262306234666365363638646362303938383436333966320a316264323738633235663061613533
          30623864396364613136356666366664333866663566663961613039313030666431393430323032
          3938633037316636300a326661663565663961646461633466623863393238636231353861646433
          63336237633861663566306639663162333338363036323536663463663739656638653136316138
          34613637306261316566383335333536366535633566393765323634636130393963336238376562
          31353063373632356566356631353336333832313962373934383831653539363931376133643837
          33363433396437396363376635316636353163663564333362656534633435646439326334396566
          64643631623431393033646461366166373465323661613632383034613864343134
        delay: 60
  rules:
    - name: Problem - OOM kills
      condition: event.title is match("Out-of-memory kills")
      action:
        run_playbook: # (4)!
          name: increase_resources.yml
    - name: Problem - Response time degradation
      condition: event.title is match("Response time degradation")
      action:
        debug: # (5)!
```

1. Small localhost only inventory, as an API is targeted

    ```yaml
    all:
      hosts:
        localhost:
          ansible_connection: local
          ansible_python_interpreter: /usr/bin/python3
    ```

2. FQCN of event source plugin from the [Dynatrace EDA collection](https://galaxy.ansible.com/ui/repo/published/dynatrace/event_driven_ansible/docs/){:target="_blank"}
3. Accessing the Dynatrace API requires a token, here as vault-encrypted string.
4. One of the builtin actions from the [`ansible.eda` collection](https://galaxy.ansible.com/ui/repo/published/ansible/eda/docs/){:target="_blank"}, runs a locally available playbook.
5. One of the builtin actions from the [`ansible.eda` collection](https://galaxy.ansible.com/ui/repo/published/ansible/eda/docs/){:target="_blank"}, mimics the debug module in ansible, ff no arguments are provided it prints the matching events along with other important properties

## Execution

=== "Rulebook Container"

    To run the rulebook activation:

    ```bash
    podman run -it --rm --name rulebook -v "$PWD:/content:Z" -w /content quay.io/ansible/ansible-rulebook:latest ansible-rulebook --rulebook rulebooks/dynatrace_problems.yml --inventory inventory.yml -S extensions/eda/plugins/event_source/ --vault-password-file vault.txt
    ```

    The command consists of the following parameters and options:

    * `--rm --name rulebook` - Container name and removal of stopped/failed containers for clean setup
    * `-v "$PWD:/content:Z"` - mounts the current directory into the container
    * `quay.io/ansible/ansible-rulebook:latest ansible-rulebook` - image with the `ansible-rulebook` installation
    * `--rulebook rulebooks/dynatrace_problems.yml` - path to the rulebook file
    * `--inventory inventory.yml` - path to inventory file
    * `-S extensions/eda/plugins/event_source/` - optional path to directory with additional event source plugins (the used container image only has the `ansible.eda` collection installed)
    * `--vault-password-file vault.txt` - path to file with vault password, if rulebook contains encrypted sensitive content

    The container is running in foreground.

=== "Installed locally"

    ```bash
    ansible-rulebook --rulebook rulebooks/dynatrace_problems.yml --inventory inventory.yml -S extensions/eda/plugins/event_source/ --vault-password-file vault.txt
    ```

    The command consists of the following parameters and options:

    * `--rulebook rulebooks/dynatrace_problems.yml` - path to the rulebook file
    * `--inventory inventory.yml` - path to inventory file
    * `-S extensions/eda/plugins/event_source/` - optional path to directory with additional event source plugins (the used container image only has the `ansible.eda` collection installed)
    * `--vault-password-file vault.txt` - path to file with vault password, if rulebook contains encrypted sensitive content

    The process is running in foreground.

??? example "Debug of event on CLI"

    Using the [`debug` action](https://docs.ansible.com/projects/rulebook/en/latest/actions.html#debug){:target="_blank"} will output everything when the event occurs which is useful for debugging and viewing all available keys and values of the event.

    ```bash
    $ podman run -it --rm --name rulebook -v "$PWD:/content:Z" -w /content  quay.io/ansible/ansible-rulebook:latest ansible-rulebook --rulebook rulebooks/dynatrace_problems.yml --inventory inventory.yml -S extensions/eda/plugins/event_source/ --vault-password-file vault.txt

    ** 2026-08-19 12:35:05.040770 [debug: kwargs] ***************************************
    {'hosts': ['all'],
    'inventory': 'inventory.yml',
    'project_data_file': None,
    'rule': 'Problem - Response time degradation',
    'rule_run_at': '2026-08-19T12:35:05.040478Z',
    'rule_set': 'Listen for events on a webhook',
    'rule_set_uuid': '285068f9-5782-4539-a080-8d43ec9c33d9',
    'rule_uuid': 'fd3ca98d-22d7-465f-b896-77736d78ff3c',
    'variables': {'event': {'affectedEntities': [{'entityId': {'id': 'SERVICE-BB07EB8904AB1CFA',
                                                                'type': 'SERVICE'},
                                                'name': 'BrokerService'}],
                            'displayId': 'P-2608133',
                            'endTime': -1,
                            'entityTags': [{'context': 'CONTEXTLESS',
                                            'key': 'dt.host_group.id',
                                            'stringRepresentation': 'dt.host_group.id:DTU-Dynatrace-Sandbox-HG',
                                            'value': 'DTU-Dynatrace-Sandbox-HG'},
                                            {'context': 'CONTEXTLESS',
                                            'key': 'aws.account.id',
                                            'stringRepresentation': 'aws.account.id:408059194125',
                                            'value': '408059194125'},
                                            {'context': 'CONTEXTLESS',
                                            'key': 'aws.region',
                                            'stringRepresentation': 'aws.region:us-east-1',
                                            'value': 'us-east-1'},
                                            {'context': 'ENVIRONMENT',
                                            'key': 'DT_RELEASE_PRODUCT',
                                            'stringRepresentation': '[Environment]DT_RELEASE_PRODUCT:easytrade',
                                            'value': 'easytrade'},
                                            {'context': 'CONTEXTLESS',
                                            'key': 'k8s.cluster.name',
                                            'stringRepresentation': 'k8s.cluster.name:dynakube',
                                            'value': 'dynakube'},
                                            {'context': 'CONTEXTLESS',
                                            'key': 'k8s.namespace.name',
                                            'stringRepresentation': 'k8s.namespace.name:easytrade',
                                            'value': 'easytrade'},
                                            {'context': 'ENVIRONMENT',
                                            'key': 'DT_RELEASE_VERSION',
                                            'stringRepresentation': '[Environment]DT_RELEASE_VERSION:latest',
                                            'value': 'latest'}],
                            'impactLevel': 'SERVICES',
                            'impactedEntities': [{'entityId': {'id': 'SERVICE-BB07EB8904AB1CFA',
                                                                'type': 'SERVICE'},
                                                'name': 'BrokerService'}],
                            'k8s.cluster.name': ['dynakube'],
                            'k8s.cluster.uid': ['614f6624-7247-4283-b773-049421fb6040'],
                            'k8s.namespace.name': ['easytrade'],
                            'managementZones': [],
                            'meta': {'received_at': '2026-08-19T12:35:05.029066Z',
                                    'source': {'name': 'Dynatrace sgb38850',
                                                'type': 'dt_esa_api'},
                                    'uuid': 'c4d419a6-0288-4f4b-924d-75d727d4234f'},
                            'problemFilters': [],
                            'problemId': '-6360532917658055610_1787142540000V2',
                            'recentComments': {'comments': [], 'totalCount': 0},
                            'rootCauseEntity': None,
                            'severityLevel': 'PERFORMANCE',
                            'startTime': 1787142840000,
                            'status': 'OPEN',
                            'title': 'Response time degradation'}}}
    *************************************************************************************

    ** 2026-08-19 12:35:05.045355 [debug: facts] ****************************************
    []
    *************************************************************************************

    ```
