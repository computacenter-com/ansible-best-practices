---
icon: lucide/package
---

# Execution Environments

Ansible automation can be run in containers, using container images known as Execution Environments (EE) that act as control nodes.  
An Execution Environment image contains the following packages as standard:

* `ansible-core`
* `ansible-runner`
* Python
* Ansible content dependencies

In addition to the standard packages, an EE **can** also contain:

* one or more Ansible collections and their dependencies
* other custom components

## EE Definition File

Define at least the definition file for the Execution Environment and other files, depending on your use-case.

=== "EE definition file"
    !!! example "execution-environment.yml"
        ```yaml
        ---
        version: 3

        images:
          base_image:
            name: registry.redhat.io/ansible-automation-platform-26/ee-supported-rhel9:latest  # (1)!

        dependencies: # (2)!
          galaxy: requirements.yml # (3)!
          python: requirements.txt # (4)!
          system: bindep.txt

        ```

        1. Some more useful base images:
            * registry.redhat.io/ansible-automation-platform-26/ee-minimal-rhel9:latest
            * ghcr.io/ansible-community/community-ee-base:latest
            * ghcr.io/ansible-community/community-ee-minimal:latest
            * registry.access.redhat.com/ubi9/ubi:latest
            * quay.io/rockylinux/rockylinux:9
        2. If you want to install a specific Ansible version add this configuration under the `dependencies` key:
        ```yaml
        dependencies:
          ansible_core:
            package_pip: ansible-core==2.14.3
        ```
        3. Instead of using a separate file, you can provide collections (and roles) as a list:
        ```yaml
        dependencies:
          galaxy:
            collections:
              - kubernetes.core
            roles:
              - timgrt.terraform
        ```
        4. Instead of using a separate file, you can provide the Python packages as a list:
        ```yaml
        dependencies:
          python:
            - awxkit
            - boto
            - botocore
            - boto3
            - openshift
            - requests-oauthlib
        ```
=== "Collection Dependencies"
    !!! example "requirements.yml"

        ```yaml
        ---
        collections:
          - redhat.openshift
        ```

=== "Python Dependencies"
    !!! example "requirements.txt"

        ```text
        awxkit>=13.0.0
        boto>=2.49.0
        botocore>=1.12.249
        boto3>=1.9.249
        openshift>=0.6.2
        requests-oauthlib
        ```

        !!! tip

            **Add/install the `ansible-lint` package alongside the other Python dependencies!**  
            This ensures you can use `ansible-navigator lint`, as well as everybody utilizing the EE does use the same version of the linter.

=== "Cross-Platform requirements"
    !!! example "bindep.txt"

        If there are RPMS necessary, put them here.

        ```text
        subversion [platform:rpm]
        subversion [platform:dpkg]
        ```

For more information, go to the [Ansible Builder Documentation](https://docs.ansible.com/projects/builder/en/stable/definition/){ target=_blank }.

The `requirements.*` files should already be part of the [project directory](../ansible/project.md#dependencies), add the `execution-environment.yml` to the project root directory as well.

## Build EE image

The Builder expects the EE configuration in the current working directory with the name `execution-environment.yml`.

To build the EE, run this command:

```bash
ansible-builder build build -t custom-ee -v 3
```

!!! tip

    Always use the `-v 3` verbosity setting, this helps understanding what is done during the build process.

Definition files with a different name must be provided via the `-f` parameter.

The resulting container images can be viewed with the `podman images` command:

``` { .bash .no-copy }
$ podman images
REPOSITORY                        TAG       IMAGE ID       CREATED              SIZE
localhost/custom-ee               latest    39466794b6cd   6 minutes ago        540 MB
```

!!! tip

    You can also build Execution Environments with *ansible-navigator*, the Builder is installed alongside Navigator.

    ```bash
    ansible-navigator builder build -t custom-ee -v 3 --ee false # (1)!
    ```

    1. The parameter `--ee false` seems counter-intuitive at first, but is necessary to run locally. Without it, the Navigator tries to download the `ghcr.io/ansible/community-ansible-dev-tools:latest` image.

Once, the EE image is built, execute it with [Ansible Navigator](../ansible/execution.md#execute-with-ansible-navigator) or push it to a container registry and use it in AAP/AWX.

## Possible EE build errors

During the build process, errors may occur, depending on your build environment, used base image, collections or dependencies to be installed.  
The following shows some possible errors and how to mitigate them.

=== "/usr/bin/dnf: No such file or directory"

    The build process may fail with the following error:

    !!! failure ""
        ``` { .bash .no-copy hl_lines=3 }
        ...
        + /usr/bin/dnf install -y gcc libssh libssh-devel python3-Cython python3-cffi python3-cryptography python3-lxml python3-pycparser python3-six python3.11-devel systemd-devel
        /output/scripts/assemble: line 73: /usr/bin/dnf: No such file or directory
        Error: building at STEP "RUN /output/scripts/assemble": while running runtime: exit status 127
        ...
        ```

    This error most likely shows when using **minimal** base images, e.g. `registry.redhat.io/ansible-automation-platform-26/ee-minimal-rhel9:latest` where a lightweight `dnf` is used.  

    !!! success "Solution"

        **Adjust the package manager path.**  

    Add the following setting to your `execution-environment.yml`:

    ```yaml
    options:
      package_manager_path: /usr/bin/microdnf
    ```

=== "No module named pip"

    The build process may fail with the following error:

    !!! failure ""

        ``` { .bash .no-copy hl_lines=3 }
        ...
        + /usr/bin/python3 -m pip install --cache-dir=/output/wheels -r /tmp/src/requirements.txt
        /usr/bin/python3: No module named pip
        Error: building at STEP "RUN /output/scripts/assemble": while running runtime: exit status 1
        ```

    This error may occur if the `pip` utility is not installed or can not be deduced correctly.

    !!! success "Solution"

        **Define the Python Interpreter.**  

    Get the Python Version of the base image, if already installed:

    ```bash
    podman run -it registry.redhat.io/ansible-automation-platform-26/ee-minimal-rhel9:latest python3 --version
    ```

    Add the following setting to your `execution-environment.yml`:

    ```yaml
    dependencies:
      python_interpreter:
        package_system: python312
        python_path: /usr/bin/python3.12
    ```

    You can also define a newer Python version, but you must ensure that it can be installed with the repository settings in the container base image.

=== "No module named 'ansible'"

    The build process may fail with the following error:

    !!! failure ""

        ``` { .bash .no-copy hl_lines=5 }
        ...
        + /usr/bin/python3.11 -c 'import ansible ; import ansible_runner'
        Traceback (most recent call last):
        File "<string>", line 1, in <module>
        ModuleNotFoundError: No module named 'ansible'
        + '[' 1 -ne 0 ']'
        + cat
        **********************************************************************
        ERROR - Missing Ansible or Ansible Runner for selected Python
        ```

    !!! success "Solution"

        **Define ansible-core and ansible-runner in the dependencies section.**  

    Add the following setting to your `execution-environment.yml`:

    ```yaml
    dependencies:
      ansible_core:
        package_pip: ansible-core # (1)!
      ansible_runner:
        package_pip: ansible-runner
    ```

    1. You can also define a specific version, e.g. `package_pip: ansible-core==2.16.18`

=== "ansible-galaxy: command not found"

    The build process may fail with the following error:

    !!! failure ""

        ``` { .bash .no-copy hl_lines=2 }
        ...
        + ansible-galaxy --version
        /output/scripts/check_galaxy: line 23: ansible-galaxy: command not found
        ```

    This error most likely occurs when using base images like `registry.access.redhat.com/ubi9/ubi:latest` where no Ansible is installed yet.

    !!! success "Solution"

        **Define ansible-core and ansible-runner in the dependencies section.**  

    Add the following setting to your `execution-environment.yml`:
    Needs the following configuration:

    ```yaml
    dependencies:
      ansible_runner:
        package_pip: ansible-runner
      ansible_core:
        package_pip: ansible-core # (1)!
    ```

    1. You can also define a specific version, e.g. `package_pip: ansible-core==2.16.18`

    !!! tip
        **Update Python as well!**  
        The base image uses the default Python 3.9, which only allows ansible-core 2.15.x!

        ```yaml
        dependencies:
          ansible_runner:
            package_pip: ansible-runner
          ansible_core:
            package_pip: ansible-core
          python_interpreter:
            package_system: python312
            python_path: /usr/bin/python3.12
        ```
