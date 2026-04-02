---
icon: lucide/list-ordered
---

# Tasks

**Tasks should always be inside of a role.** Do not use tasks in a play directly.  
Logically related tasks are to be separated into individual files, the `main.yml` of a role only **imports** other task files.

``` { .bash .no-copy }
.
└── roles
    └── k8s_bootstrap
        └── tasks
            ├── install_kubeadm.yml
            ├── main.yml
            └── prerequisites.yml
```

The file name of a task file should describe the content.

```yaml title="roles/k8s_bootstrap/tasks/main.yml"
--8<-- "example-role-main-task.yml"
```

??? info "`noqa` statement"
    The file `main.yml` only references other task-files, still, the *ansible-lint* utility would trigger, as every *task* should have the `name` parameter.  
    While this is correct (and you should always name your **actual** *tasks*), the *name* parameter on *import* statements is **not shown anyway**, as they are pre-processed at the time playbooks are parsed. Take a look at the following section regarding *import vs. include*.  

    !!! success
        Therefore, silencing the linter in this particular case with the `noqa` statement is acceptable.  

    In contrast, *include* statements like `ansible.builtin.include_tasks` should have the `name` parameter, as these statements are processed when they are encountered during the execution of the playbook.

## import vs. include

Ansible offers two ways to reuse tasks: *statically* with `ansible.builtin.import_tasks` and *dynamically* with `ansible.builtin.include_tasks`.  
Each approach to reuse distributed Ansible artifacts has advantages and limitations, take a look at the [Ansible documentation for an in-depth comparison of the two statements](https://docs.ansible.com/ansible/devel/playbook_guide/playbooks_reuse.html#comparing-includes-and-imports-dynamic-and-static-reuse){:target="_blank"}.  

!!! tip
    In most cases, use the static `ansible.builtin.import_tasks` statement, it has more advantages than disadvantages.

One of the biggest disadvantages of the dynamic *include_tasks* statement, syntax errors are not found easily with `--syntax-check` or by using *ansible-lint*. You may end up with a failed playbook, although all your testing looked fine. Take a look at the following example, the recommended `ansible.builtin.import_tasks` statement on the left, the `ansible.builtin.include_tasks` statement on the right.

!!! quote ""

    <div class="grid" markdown>

    !!! success "Syntax or linting errors found"

        Using *static* `ansible.builtin.import_tasks`:

        ```{ .yaml title="roles/prerequisites/tasks/main.yml" .no-copy}
        ---
        - ansible.builtin.import_tasks: prerequisites.yml
        - ansible.builtin.import_tasks: install_kubeadm.yml
        ```

        Task-file with syntax error (module-parameters are not indented correctly):

        ```{ .yaml title="install_kubeadm.yml" hl_lines="3 4" .no-copy}
        - name: Install Kubernetes Repository
          ansible.builtin.template:
          src: kubernetes.repo.j2
          dest: /etc/yum.repos.d/kubernetes.repo
        ```

        Running playbook with `--syntax-check` or running `ansible-lint`:

        ```{ .bash .no-copy}
        $ ansible-playbook k8s_install.yml --syntax-check
        ERROR! conflicting action statements: ansible.builtin.template, src

        The error appears to be in '/home/timgrt/kubernetes_installation/roles/k8s-bootstrap/tasks/install_kubeadm.yml': line 3, column 3, but may
        be elsewhere in the file depending on the exact syntax problem.

        The offending line appears to be:


        - name: Install Kubernetes Repository
          ^ here
        $ ansible-lint k8s_install.yml
        WARNING  Listing 1 violation(s) that are fatal
        syntax-check[specific]: conflicting action statements: ansible.builtin.template, src
        roles/k8s_bootstrap/tasks/install_kubeadm.yml:3:3


                          Rule Violation Summary  
        count tag                    profile rule associated tags
            1 syntax-check[specific] min     core, unskippable  

        Failed: 1 failure(s), 0 warning(s) on 12 files.
        ```

    !!! failure "Syntax or linting errors **NOT** found!"

        Using *dynamic* `ansible.builtin.include_tasks`:

        ```{ .yaml title="roles/prerequisites/tasks/main.yml" .no-copy}
        ---
        - ansible.builtin.include_tasks: prerequisites.yml
        - ansible.builtin.include_tasks: install_kubeadm.yml
        ```

        Task-file with syntax error (module-parameters are not indented correctly):

        ```{ .yaml title="install_kubeadm.yml" hl_lines="3 4" .no-copy}
        - name: Install Kubernetes Repository
          ansible.builtin.template:
          src: kubernetes.repo.j2
          dest: /etc/yum.repos.d/kubernetes.repo
        ```
        Running playbook with `--syntax-check` or running `ansible-lint`:

        ```{ .bash .no-copy}
        $ ansible-playbook k8s_install.yml --syntax-check

        playbook: k8s_install.yml
        $ ansible-lint k8s_install.yml

        Passed: 0 failure(s), 0 warning(s) on 12 files. Last profile that met the validation criteria was 'production'.
        ```

        !!! danger
            As the `--syntax-check` or `ansible-lint` are doing a static *code* analysis and the task-files are **not** included statically, possible syntax errors are not recognized!

        Your playbook will fail when running it live, revealing the syntax error.

    </div>

!!! info
    There are also big differences in resource consumption and performance, *imports* are quite lean and fast, while *includes* require a lot of management and accounting.

## Naming tasks

It is possible to leave off the *name* for a given task, though it is recommended to provide a description about why something is being done instead. This description is shown when the playbook is run.  
Write task names in the imperative (e.g. *"Ensure service is running"*), this communicates the action of the task. Start with a capital letter.

=== "Good"
    !!! success ""

        ```yaml
        --8<-- "example-install-package-task.yml"
        ```

=== "Bad"
    !!! failure ""

        ``` { .yaml .no-copy }
        - package:
            name: httpd
            state: present
        ```

        Using name parameter, but not starting with capital letter, nor describing the task properly.

        ``` { .yaml .no-copy }
        - name: install package
          package:
            name: httpd
            state: present
        ```

## Tags

Don't use too many tags, it gets confusing very quickly.  
Tags should only be allowed for imported task files within the `main.yml` of a role. Tags at the task level in sub-task files should be avoided.

```yaml title="tasks/main.yml"
--8<-- "example-main-with-tags-task.yml"
```

Try to use the same tags across your roles, this way you would be able to run only e.g. *installation* tasks from multiple roles.

## Idempotence

Each task must be idempotent, if non-idempotent modules are used (*command*, *shell*, *raw*) these tasks must be developed via appropriate parameters or conditions to an idempotent mode of operation.  

!!! tip
    In general, the use of non-idempotent modules should be reduced to a necessary minimum.

### *command* vs. *shell* module

In most of the use cases, both shell and command modules perform the same job. However, there are few main differences between these two modules. The [*command*](https://docs.ansible.com/ansible/latest/collections/ansible/builtin/command_module.html){:target="_blank"} module uses the Python interpreter on the target node (as all other modules), the [*shell*](https://docs.ansible.com/ansible/latest/collections/ansible/builtin/shell_module.html){:target="_blank"} module runs a real shell on the target (pipes and redirects are available, as well as access to environment variables).

!!! tip
    Always try to use the `command` module over the `shell` module, if you do not explicitly need shell functionality.

Parsing shell meta-characters can lead to unexpected commands being executed if quoting is not done correctly so it is more secure to use the command module when possible. To sanitize any variables passed to the shell module, you should use `{{ var | quote }}` instead of  
just `{{ var }}` to make sure they do not include evil things like semicolons.

### *creates* and *removes*

When using non-idempotent modules like `command` or `shell` it is **your** responsibility to ensure the executed command does not do anything unexpected.  
Ideally, the task reports an *ok* state, if the desired state is reached, or a *changed* state if not, this can be achieved by using the `creates` or `removes` parameter.  
The parameter expects a filename or glob pattern, if a matching file (when using `creates`) already exists, the command will not be run. Check mode is also supported for non-idempotent modules when either of the parameters are specified. The module will check for the existence of the file and report the correct changed status. If these are not supplied, the task will be skipped.

=== "Good"
    !!! success ""

        ```yaml
        - name: Initialize PostgreSQL database
          ansible.builtin.command:
            cmd: /usr/bin/postgresql-setup --initdb
            creates: /var/lib/pgsql/data/PG_VERSION
        ```

        If the file `/var/lib/pgsql/data/PG_VERSION` exists, the command is not run, the task will return *ok*.

        ``` { .ansible-output .no-copy title="Database is already initialized from a previous run, no changed/failed state from command module" }
        $ ansible-playbook postgres_installation.yml

        PLAY [PostgreSQL installation] ******************************************************************************************

        TASK [Install Postgres] *************************************************************************************************
        ok: [instance1]

        TASK [Initialize PostgreSQL database] ***********************************************************************************
        ok: [instance1]

        TASK [Start PostgreSQL] *************************************************************************************************
        ok: [instance1]
        ```

        When running the playbook in **check mode** the task using the `command` module is **not skipped** (it still won't execute the command!), but will check for the existence of the file and show the state accordingly.

        ??? example

            ``` { .ansible-output .no-copy title="Fresh installation, running in Check mode, correct changed state from command module" }
            $ ansible-playbook postgres_installation.yml -C

            PLAY [PostgreSQL installation] ******************************************************************************************

            TASK [Install Postgres] *************************************************************************************************
            changed: [instance1]

            TASK [Initialize PostgreSQL database] ***********************************************************************************
            changed: [instance1]

            ...
            ```

=== "Bad"

    !!! failure ""

        ```yaml
        - name: Initialize PostgreSQL database
          ansible.builtin.command:
            cmd: /usr/bin/postgresql-setup --initdb
        ```

        **Without** the `creates` parameter the command is **always** executed, it will show *changed* or even fail...  

        ``` { .ansible-output .no-copy title="Database is already initialized from a previous run, hopefully the command does not do something unexpected..." }
        $ ansible-playbook postgres_installation.yml

        PLAY [PostgreSQL installation] ******************************************************************************************

        TASK [Install Postgres] *************************************************************************************************
        ok: [instance1]

        TASK [Initialize PostgreSQL database] ***********************************************************************************
        [ERROR]: Task failed: Module failed: non-zero return code
        Origin: /home/timgrt/automation-demo/test2.yml:14:7

        12         state: present
        13  
        14     - name: Initialize PostgreSQL database
                ^ column 7

        fatal: [instance1]: FAILED! => {"changed": true, "cmd": ["/usr/bin/postgresql-setup", "--initdb"], "delta": "0:00:00.090430", "end": "2026-03-31 15:49:23.216778", "msg": "non-zero return code", "rc": 1, "start": "2026-03-31 15:49:23.126348", "stderr": " * Initializing database in '/var/lib/pgsql/data'\nERROR: Data directory /var/lib/pgsql/data is not empty!\nERROR: Initializing database failed, possibly see /var/lib/pgsql/initdb_postgresql.log", "stderr_lines": [" * Initializing database in '/var/lib/pgsql/data'", "ERROR: Data directory /var/lib/pgsql/data is not empty!", "ERROR: Initializing database failed, possibly see /var/lib/pgsql/initdb_postgresql.log"], "stdout": "", "stdout_lines": []}
        ```

        !!! danger "Error"

            Running the task failed with `ERROR: Data directory /var/lib/pgsql/data is not empty!`!  
            While this is good (and expected), the playbook should continue. The initialization command can't be run again, it must be checked if it was executed earlier. This could be done by a previous task checking for a non-empty data directory with the `ansible.builtin.stat` module or, even better, with the `creates` parameter in the same task.

        When running in check mode, the task using the `command` module is skipped, **no prediction is made**.

        ??? example

            ``` { .ansible-output .no-copy }
            $ ansible-playbook postgres_installation.yml -C

            PLAY [PostgreSQL installation] ******************************************************************************************

            TASK [Install Postgres] *************************************************************************************************
            changed: [instance1]

            TASK [Initialize PostgreSQL database] *************************************************************************************************************************
            skipping: [instance1]

            ...
            ```

The `removes` parameter works similar, only that it checks for a path or file removed by something.

### *failed_when* and *changed_when*

Non-idempotent modules like `command` or `shell` **always** return a *changed* state, although in some cases, no *actual* change is done on the target system. Additionally, sometimes the command or module does return a *failed* result (as it checks for a return code zero), but a return code of 1 is also acceptable (highly depends on use-case).  

In both cases, you can override the changed and/or failed check with `changed_when` or `failed_when`.

=== "Good"

    !!! success ""

        ```yaml
        --8<-- "example-changed-when-task.yml"
        ```

        ```yaml
        --8<-- "example-failed-when-task.yml"
        ```

        1. A *folded block scalar*, will fold newlines to spaces; it is used to make what would otherwise be a very long line easier to read and edit, indentation will be ignored.  
        Take a look at the [YAML Syntax Basics](https://docs.ansible.com/projects/ansible/latest/reference_appendices/YAMLSyntax.html){:target="_blank"} in the documentation.

=== "Bad"

    !!! failure ""

        This task never reports a changed state or fails when an error occurs.

        ``` { .yaml .no-copy }
        - name: Install webserver package
          shell: sudo yum install http
          changed_when: false
          failed_when: false
        ```

If the command does not really change anything **and** the command will always return an answer, it is acceptable to set `changed_when` to `false`.

## Modules (and Collections)

Use the *full qualified collection names (FQCN)* for modules, they are supported since Version 2.9 and ensures your tasks are set for the future.

=== "Good"

    !!! success ""

        ```yaml
        --8<-- "example-install-package-task.yml"
        ```

=== "Bad"

    !!! failure ""

        ``` { .yaml .no-copy }
        - package:
            name: httpd
            state: present
        ```

In Ansible 2.10, many plugins and modules have migrated to **Collections** on Ansible Galaxy. Your playbooks should continue to work without any changes. Using the FQCN in your playbooks ensures the explicit and authoritative indicator of which collection to use as some collections may contain duplicate module names.

## Module parameters

### Module defaults

The `module_defaults` keyword can be used at the play, block, and task level. Any module arguments explicitly specified in a task will override any established default for that module argument.  
It makes the most sense to define the *module defaults* at [*play* level, take a look in that section](playbook.md#module-defaults) for an example and things to consider.

### Permissions

When using modules like `copy` or `template` you can (and should) set permissions for the files/templates deployed with the `mode` parameter.

For those used to */usr/bin/chmod*, remember that modes are actually octal numbers.  
Add a **leading zero** (or `1` for setting sticky bit), showing Ansible’s YAML parser it is an octal number **and** quote it (like `"0644"` or `"1777"`), this way Ansible receives a string and can do its own conversion from string into number.

!!! warning
    Giving Ansible a number without following one of these rules will end up with a decimal number which can have unexpected results.

=== "Good"

    !!! success ""

        ```yaml
        --8<-- "example-copy-template-task.yml"
        ```

=== "Bad"

    !!! failure ""

        Missing leading zero:

        ``` { .yaml .no-copy }
        - name: copy index
          template:
            src: welcome.html
            dest: /var/www/html/index.html
            mode: 644
            owner: apache
            group: apache
          become: true
        ```

        This leads to these permissions!

        ``` { .bash .no-copy }
        [root@demo /]# ll /var/www/html/
        total 68
        --w----r-T 1 apache apache 67691 Nov 18 14:30 index.html
        ```

### State definition

The `state` parameter is optional to a lot of modules. Whether `state: present` or `state: absent`, it’s always best to leave that parameter in your playbooks to make it clear, especially as some modules support additional states.

## Files vs. Templates

Ansible differentiates between *files* for static content (deployed with `copy` module) and *templates* for content, which should be rendered dynamically with Jinja2 (deployed with `template` module).  

!!! tip
    In almost every case, use *templates*, deployed via `template` module.  

Even if there currently is nothing in the file that is being templated, if there is the possibility in the future that it might be added, having the file handled by the `template` module makes adding that functionality much simpler than if the file is initially handled by the `copy` module( and then needs to be moved before it can be edited).

Additionally, you now can add a *marker*, indicating that manual changes to the file will be lost:

=== "Template"

    ```yaml+jinja
    {{ ansible_managed | ansible.builtin.comment }}
    ```

=== "Rendered output"

    ```cfg
    #
    # Ansible Managed
    #
    ```

??? info "`ansible.builtin.comment` filter"
    By default, `{{ ansible_managed }}` is replaced by the string `Ansible Managed` as is (can be adjusted in the [`ansible.cfg`)](https://docs.ansible.com/ansible/latest/reference_appendices/config.html#default-managed-str){:target="_blank"}.  
    In most cases, the appropriate *comment* symbol must be prefixed, this should be done with the `ansible.builtin.comment` filter.  
    For example, `.xml` files need to be commented differently, which can be configured:

    === "Template"

        ```yaml+jinja
        {{ ansible_managed | ansible.builtin.comment('xml') }}
        ```

    === "Rendered output"
        ```xml
        <!--
        -
        - Ansible managed
        -
        -->
        ```

    You can also use the `decorate` parameter to choose the symbol yourself.  
    Take a look at the [Ansible documentation for additional information](https://docs.ansible.com/ansible/latest/collections/ansible/builtin/comment_filter.html){:target="_blank"}.

When using the `template` module, append `.j2` to the template file name. Keep filenames and templates as close to the name on the destination system as possible.

## Conditionals

If the `when:` condition results in a line that is very long, and is an `and` expression, then break it into a list of conditions.

=== "Good"
    !!! success ""

        ```yaml
        --8<-- "example-multiple-when-conditions-task.yml"
        ```

=== "Bad"
    !!! failure ""

        ``` { .yaml .no-copy }
        - name: Set motd message for k8s worker node
          copy:
            content: "This host is used as k8s worker.\n"
            dest: /etc/motd
          when: inventory_hostname in groups['kubeworker'] and kubeadm_join_result.rc == 0
        ```

When using conditions on *blocks*, move the `when` statement to the top, below the *name* parameter, to improve readability.

=== "Good"
    !!! success ""

        ```yaml
        --8<-- "example-block-with-when-tasks.yml"
        ```

=== "Bad"
    !!! failure ""

        ``` { .yaml .no-copy }
        - name: Install, configure, and start Apache
          block:
            - name: Install httpd and memcached
              ansible.builtin.package:
                name:
                - httpd
                - memcached
                state: present

            - name: Apply the foo config template
              ansible.builtin.template:
                src: templates/src.j2
                dest: /etc/foo.conf

            - name: Start service bar and enable it
              ansible.builtin.service:
                name: bar
                state: started
                enabled: True
          when: ansible_facts['distribution'] == 'CentOS'
        ```

Avoid the use of `when: foo_result is changed` whenever possible. Use handlers, and, if necessary, handler chains to achieve this same result.

## Loops

Ansible offers the `loop`, `with_<lookup>`, and `until` keywords to execute a task multiple times.  
The normal use case for [`until`](#retry-until-condition-is-met){ no-data-preview } has to do with tasks that are likely to fail, while `loop` and `with_<lookup>` are meant for repeating tasks with slight variations.

!!! tip
    **Use the `loops` keyword over the `with_<lookup>` statement!**  
    Converting from `with_<lookup>` to `loop` is described with a [Migration Guide](https://docs.ansible.com/ansible/latest/user_guide/playbooks_loops.html#migrating-from-with-x-to-loop){:target="_blank"} in the Ansible documentation

The loop keyword expects **list** input.

=== "Good"
    !!! success ""

        ``` { .yaml hl_lines="6" }
        --8<-- "example-loop-task.yml"
        ```

=== "Bad"
    !!! failure ""

        ``` { .yaml .no-copy hl_lines="6" }
        - name: Create local users
          ansible.builtin.user:
            name: "{{ item }}"
            password_expire_max: "{{ password_expire_max }}"
            state: present
          with_items: "{{ user_list }}"
        ```

Take care when using the `lookup` keyword in the `loop` statement, as it returns a string of comma-separated values by default, use the Jinja2 [`query` function as it always returns a list](https://docs.ansible.com/projects/ansible/latest/playbook_guide/playbooks_loops.html#ensuring-list-input-for-loop-using-query-rather-than-lookup){:target="_blank"}.

### Retry until condition is met

Use the `until` keyword to retry a task until a certain condition is met (think: *while-do-loop*):

```yaml
--8<-- "example-loop-until-task.yml"
```

1. The command module always returns a changed state (if not using the `creates`/`removes` parameter). As the example command does not really change anything, setting the `changed_when` parameter to `false` so that the task always returns *ok* (or *failed* if the return code never becomes 0).

With every loop run, the output of the command module (including the *return code* `rc` field) is *registered* and checked against the *until* condition. In this case, once the return code is 0, the loop is finished. The command is executed every three seconds with 10 retries total.

!!! info inline end
    If the *until* condition is never reached, the task fails.

```ansible-output
TASK [Wait for PostgreSQL to accept connections] *******************************
FAILED - RETRYING: [instance1]: Wait for PostgreSQL to accept connections (10 retries left).
FAILED - RETRYING: [instance1]: Wait for PostgreSQL to accept connections (9 retries left).
FAILED - RETRYING: [instance1]: Wait for PostgreSQL to accept connections (8 retries left).
ok: [instance1]
```

### Nested loops

While it possible to use *nested* loops (as in a [programming language](../mindset/index.md#ansible-is-not-python)) with some *workarounds*, try to avoid this. If you do not have to execute multiple tasks in the *inner* loop, in most cases, **format the data** to achieve the same result.

??? example "Example input"

    In the following example a **list of users** requires access **to a list of databases**:

    ```yaml
    user_list:
      - alice
      - bob

    databases_list:
      - clientdb
      - employeedb
      - providerdb
    ```

=== "Formatted input"

    !!! info inline end
        You can use Jinja2 expressions to iterate over complex lists.  
        The [product filter](https://docs.ansible.com/projects/ansible/latest/playbook_guide/playbooks_filters.html#products){:target="_blank"} creates the *cartesian product* of the input lists, which is roughly equivalent to nested for-loops.

    ```yaml
    --8<-- "example-nested-loops-formatted-input-task.yml"
    ```

    1. The product filter creates a *list of lists* for the two input lists `user_list` and `databases_list`:

        ```json
        [
            [
                "alice",
                "clientdb"
            ],
            [
                "alice",
                "employeedb"
            ],
            [
                "alice",
                "providerdb"
            ],
            [
                "bob",
                "clientdb"
            ],
            [
                "bob",
                "employeedb"
            ],
            [
                "bob",
                "providerdb"
            ]
        ]
        ```

    2. Not necessary for the desired solution, but *formats* the output. See section regarding [limiting loop output](#limit-loop-output).


    ??? example "Example output"

        ```ansible-output
        TASK [Give users access to multiple databases] *********************************
        ok: [DB1] => (item=Granting alice access to clientdb)
        ok: [DB1] => (item=Granting alice access to employeedb)
        ok: [DB1] => (item=Granting alice access to providerdb)
        ok: [DB1] => (item=Granting bob access to clientdb)
        ok: [DB1] => (item=Granting bob access to employeedb)
        ok: [DB1] => (item=Granting bob access to providerdb)
        ```

=== "Multiple task files"

    !!! info inline end
        As the number of list elements can be *dynamic*, the `inlude_tasks` module is necessary. Take a look at the [import vs. include](#import-vs-include) section for additional info.

    ```yaml title="Task invoking the outer loop"
    --8<-- "example-nested-loops-outer-task.yml"
    ```

    1. Ansible sets the loop variable `item` for each loop. This means the **inner, nested loop** will *overwrite* the value of item from the outer loop. To avoid this, you need to specify the name of the variable for each loop using `loop_var` with the `loop_control` statement.

    ```yaml title="Included Task file invoking the inner loop"
    --8<-- "example-nested-loops-inner-task.yml"
    ```

    ??? example "Example output"

        ```ansible-output
        TASK [Give users access to multiple databases] *********************************
        included: /home/timgrt/demo/db_access.yml for DB1 => (item=alice)
        included: /home/timgrt/demo/db_access.yml for DB1 => (item=bob)

        TASK [Granting alice access to database] ***************************************
        ok: [DB1] => (item=clientdb)
        ok: [DB1] => (item=employeedb)
        ok: [DB1] => (item=providerdb)

        TASK [Granting bob access to database] *****************************************
        ok: [DB1] => (item=clientdb)
        ok: [DB1] => (item=employeedb)
        ok: [DB1] => (item=providerdb)
        ```

!!! success "Both solutions produce the same output"
    While the solution with the formatted input data only runs a single task, three tasks are run for the solution with the included task file.  
    **Remember, if you need actual programming logic, use a script and run it with Ansible!**

### Limit loop output

When looping over complex data structures, the console output of your task can be enormous. To limit the displayed output, use the `label` directive with `loop_control`. For example, this tasks creates users with multiple parameters in a loop:

```yaml
--8<-- "example-loop-label-task.yml"
```

1. Content of variable `user_list`:

    ```yaml
    user_list:
      - name: tgruetz
        groups: admins,docker
        append: false
        comment: Tim Grützmacher
        shell: /bin/bash
        password_expire_max: 180
      - name: joschmi
        groups: developers,docker
        append: true
        comment: Jonathan Schmidt
        shell: /bin/zsh
        password_expire_max: 90
      - name: mfrink
        groups: developers
        append: true
        comment: Mathias Frink
        shell: /bin/bash
        password_expire_max: 90
    ```

Running the playbook results in the following task output, only the content of the *name* parameter is shown instead of all key-value pairs in the list item.

=== "Good"
    !!! success ""

        ```ansible-output
        TASK [common : Create local users] *********************************************
        changed: [demo] => (item=tgruetz)
        changed: [demo] => (item=joschmi)
        changed: [demo] => (item=mfrink)
        ```

=== "Bad"
    !!! failure ""

        Not using the `label` in the `loop_control` dictionary results in a very long output:

        ``` { .ansible-output .no-copy }
        TASK [common : Create local users] *********************************************
        changed: [demo] => (item={'name': 'tgruetz', 'groups': 'admins,docker', 'append': False, 'comment': 'Tim Grützmacher', 'shell': '/bin/bash', 'password_expire_max': 90})
        changed: [demo] => (item={'name': 'joschmi', 'groups': 'developers,docker', 'append': True, 'comment': 'Jonathan Schmidt', 'shell': '/bin/zsh', 'password_expire_max': 90})
        changed: [demo] => (item={'name': 'mfrink', 'groups': 'developers', 'append': True, 'comment': 'Mathias Frink', 'shell': '/bin/bash', 'password_expire_max': 90})
        ```
