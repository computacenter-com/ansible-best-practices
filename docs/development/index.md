# Development

This topic is split into multiple sections, each section covers a different additional tool to consider when *developing* your Ansible content.

<div class="grid cards" markdown>

* :lucide-git-pull-request-arrow: &nbsp; [**Version Control**](git.md){ data-preview }

    ---
    Small guide for version controlling playbooks.

* :lucide-search-check: &nbsp; [**Linting**](linting.md){ data-preview }

    ---
    Installation and usage of the community backed Ansible Best Practice checker.

* :lucide-flask-conical: &nbsp; [**Testing**](testing.md){ data-preview }

    ---
    How to test your Ansible content during development.

* :lucide-timer: &nbsp; [**Monitoring & Troubleshooting**](monitoring.md){ data-preview }

    ---
    How to monitor your playbook for resource consumption or time taken.

* :lucide-text-search: &nbsp; [**Logging**](logging.md){ data-preview }

    ---
    How to enable and use logging.

* :lucide-blocks: &nbsp; [**Extending**](extending.md){ data-preview }

    ---
    How to create your own custom modules and plugins.

* :lucide-package: &nbsp; [**Execution Environments**](execution-environment.md){ data-preview }

    ---
    How to create your own EEs or extend existing ones.

</div>

## Tools

Each section above make use of an additional tool to support you during your Ansible content development. In most cases the standalone installation, as well as a custom container-based installation and usage method is described.  

The Ansible community provides a Container image bundling all the tools described in the sections above.

```bash
docker pull quay.io/ansible/creator-ee
```

For example you could output the version of the installed tools like this:

```bash
docker run --rm quay.io/ansible/creator-ee ansible-lint --version
```

```bash
docker run --rm quay.io/ansible/creator-ee molecule --version
```

Take a look into the respective sections for more information and additional usage instructions.
