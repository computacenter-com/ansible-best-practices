---
icon: lucide/package-question-mark
description: How to keep collections, roles and other dependencies up to date with Renovate
status: new
---

# Dependency Management

Every Ansible project has dependencies: collections and roles in the `requirements.yml`, Python packages in the `requirements.txt`, the base image of your Execution Environment, the *pre-commit* hooks and the container images used in your CI pipeline.  
Outdated dependencies lead to missing features, deprecation warnings and, more importantly, security vulnerabilities. Checking every dependency for updates by hand does not scale. [*Renovate*](https://docs.renovatebot.com/){ target=_blank } scans your repository for dependencies, checks for new versions and opens a *pull request* (or *merge request*) for every update.

## How it works

*Renovate* runs periodically against your repository, there is no need to install anything in your project, only a small configuration file is necessary.

``` .mermaid
sequenceDiagram
  participant RE as Renovate
  participant RP as Repository
  participant DS as Datasource (Galaxy, PyPI, Registry)
  participant CI as CI Pipeline
  RE->>RP: Scan files for dependencies
  RE->>DS: Look up available versions
  RE->>RP: Create branch and pull request with update
  RP->>CI: Run linting and testing
  CI->>RP: Report status
  RP->>RP: Review and merge (or automerge)
```

Every pull request contains the release notes of the updated dependency, this makes reviewing the update much easier.

!!! warning "Pin your dependencies"
    **Renovate can only update dependencies which have a version!**  
    Collections in the `requirements.yml` without a `version` key or Python packages in the `requirements.txt` without a version specifier always install the latest version, which makes your project non-reproducible. Always pin the version:

    === "Collections and roles"

        ```yaml title="requirements.yml"
        ---
        collections:
          - name: community.general
            version: 11.4.0
          - name: ansible.posix
            version: 2.1.0
        roles:
          - name: postgres
            src: https://gitlab.example.com/ansible/roles/postgres.git
            scm: git
            version: v1.4.2
        ```

    === "Python packages"

        ```text title="requirements.txt"
        ansible-core==2.19.3
        ansible-lint==26.10.1
        jmespath==1.0.1
        ```

        Files following the naming scheme `requirements-dev.txt` or `requirements-test.txt` are detected as well, use them to separate development tools like *ansible-lint* or *molecule* from the packages necessary to run your playbooks.

## Supported dependencies

*Renovate* uses *managers* to detect dependencies in files, the following managers are relevant for Ansible projects (follow the link of a manager for its documentation):

| Manager                                                                                             | Files                            | Dependencies                                           |
| --------------------------------------------------------------------------------------------------- | -------------------------------- | ------------------------------------------------------ |
| [ansible-galaxy](https://docs.renovatebot.com/modules/manager/ansible-galaxy/){ target=_blank }     | `requirements.yml`, `galaxy.yml` | Collections and roles from Galaxy or Git repositories  |
| [ansible](https://docs.renovatebot.com/modules/manager/ansible/){ target=_blank }                   | `tasks/*.yml`                    | Container images used in tasks (`image:` key)          |
| [pip_requirements](https://docs.renovatebot.com/modules/manager/pip_requirements/){ target=_blank } | `requirements.txt`               | Python packages, e.g. *ansible-core* or *ansible-lint* |
| [pre-commit](https://docs.renovatebot.com/modules/manager/pre-commit/){ target=_blank }             | `.pre-commit-config.yaml`        | *pre-commit* hooks                                     |
| [dockerfile](https://docs.renovatebot.com/modules/manager/dockerfile/){ target=_blank }             | `Containerfile`, `Dockerfile`    | Base images                                            |
| [github-actions](https://docs.renovatebot.com/modules/manager/github-actions/){ target=_blank }     | `.github/workflows/*.yml`        | Actions and container images used in workflows         |
| [gitlabci](https://docs.renovatebot.com/modules/manager/gitlabci/){ target=_blank }                 | `.gitlab-ci.yml`                 | Container images used in pipelines                     |

A complete list of all available managers is provided in the [Renovate documentation](https://docs.renovatebot.com/modules/manager/){ target=_blank }.

!!! info
    There is no built-in manager for the [Execution Environment definition file][ee-definition-file]{ data-preview }, the base image can be updated with a [custom manager](#execution-environment-base-image). <!-- markdownlint-disable-line MD052 -->

## Installation

How to run *Renovate* depends on where your repository is hosted, all options are described in [Running Renovate](https://docs.renovatebot.com/getting-started/running/){ target=_blank }.

=== "GitHub"

    For repositories on *github.com*, install the free [Mend Renovate App](https://github.com/apps/renovate){ target=_blank } and grant it access to your repositories.  
    *Renovate* opens an [*onboarding*](https://docs.renovatebot.com/getting-started/installing-onboarding/){ target=_blank } pull request containing a `renovate.json` file, after merging it, *Renovate* starts creating pull requests for updates.

=== "GitLab (self-hosted)"

    For self-hosted GitLab instances, run *Renovate* as a [scheduled pipeline](https://docs.gitlab.com/ci/pipelines/schedules/){ target=_blank } in a dedicated project, using the official container image.

    ```yaml title=".gitlab-ci.yml"
    renovate:
      image: ghcr.io/renovatebot/renovate:44
      rules:
        - if: $CI_PIPELINE_SOURCE == "schedule"
      variables:
        RENOVATE_PLATFORM: gitlab
        RENOVATE_ENDPOINT: $CI_API_V4_URL
        RENOVATE_AUTODISCOVER: "true"
        RENOVATE_AUTODISCOVER_FILTER: "ansible/*"
        RENOVATE_GIT_AUTHOR: "Renovate Bot <renovate-bot@example.com>"
        LOG_LEVEL: info
      script:
        - renovate
    ```

    Store the following masked CI/CD variables in the project:

    * `RENOVATE_TOKEN` - an access token of a (technical) user with the `api` scope
    * `RENOVATE_GITHUB_COM_TOKEN` - a read-only *github.com* token, used to fetch release notes and to avoid rate limiting

    Set `RENOVATE_GIT_AUTHOR` to the name and mail address of your technical user, otherwise the commits are created with the default author of the *Mend Renovate App*.

    With `RENOVATE_AUTODISCOVER`, *Renovate* processes all repositories the user has access to, the filter limits it to the *ansible* group.  
    Take a look at the [GitLab platform](https://docs.renovatebot.com/modules/platform/gitlab/){ target=_blank } and the [self-hosted configuration](https://docs.renovatebot.com/self-hosted-configuration/){ target=_blank } documentation for all available options.

=== "Container (CLI)"

    For testing purposes, *Renovate* can be run from the command line against a single repository on *github.com*. Export a token with access to the repository first:

    ```bash
    export RENOVATE_TOKEN=<your-token>
    ```

    ```bash
    podman run --rm -e RENOVATE_TOKEN -e LOG_LEVEL=debug ghcr.io/renovatebot/renovate:44 --dry-run=full <owner>/<repository>
    ```

    With `--dry-run=full` *Renovate* outputs which updates it would propose, without creating any branches or pull requests.

    ??? example "Example output"

        ```{ .bash .no-copy }
        $ podman run --rm -e RENOVATE_TOKEN -e LOG_LEVEL=debug ghcr.io/renovatebot/renovate:44 --dry-run=full computacenter-com/ansible-best-practices
         INFO: Renovate started
         INFO: Repository started (repository=computacenter-com/ansible-best-practices)
        [...output cut for readability...]
         INFO: DRY-RUN: Would commit files to branch renovate/python-3.x. See debug logs for raw commit information (repository=computacenter-com/ansible-best-practices, branch=renovate/python-3.x)
         INFO: DRY-RUN: Would close Dependency Dashboard (repository=computacenter-com/ansible-best-practices)
         INFO: Repository finished (repository=computacenter-com/ansible-best-practices)
        ```

## Configuration

*Renovate* is configured with a `renovate.json` file, either in the project root directory, in the `.github/` or the `.gitlab/` folder (see [configuration location](https://docs.renovatebot.com/getting-started/installing-onboarding/#configuration-location){ target=_blank }). The minimal configuration only extends the recommended preset:

```json title="renovate.json"
{
  "$schema": "https://docs.renovatebot.com/renovate-schema.json",
  "extends": ["config:recommended"]
}
```

The [`config:recommended`](https://docs.renovatebot.com/presets-config/#configrecommended){ target=_blank } preset provides sensible defaults, e.g. a [*Dependency Dashboard*](https://docs.renovatebot.com/key-concepts/dashboard/){ target=_blank } issue which lists all pending updates, and groups known monorepo packages.

### Configuration for Ansible projects

The following configuration is a good starting point for Ansible projects:

```json title="renovate.json"
{
  "$schema": "https://docs.renovatebot.com/renovate-schema.json",
  "extends": ["config:recommended"],
  "timezone": "Europe/Berlin",
  "schedule": ["before 6am on monday"],
  "minimumReleaseAge": "3 days",
  "labels": ["dependencies"],
  "pre-commit": {
    "enabled": true
  },
  "packageRules": [
    {
      "description": "Group all collections and roles into a single pull request",
      "matchManagers": ["ansible-galaxy"],
      "groupName": "Ansible Galaxy dependencies"
    },
    {
      "description": "Group Ansible development tools into a single pull request",
      "matchManagers": ["pip_requirements"],
      "matchPackageNames": ["ansible-lint", "ansible-navigator", "molecule", "molecule-plugins"],
      "groupName": "Ansible development tools"
    },
    {
      "description": "Minor updates of ansible-core may remove deprecated features",
      "matchPackageNames": ["ansible-core"],
      "matchUpdateTypes": ["minor"],
      "addLabels": ["breaking-change"]
    },
    {
      "description": "Automerge minor and patch updates of pre-commit hooks",
      "matchManagers": ["pre-commit"],
      "matchUpdateTypes": ["minor", "patch"],
      "automerge": true
    },
    {
      "description": "Highlight major updates, they may contain breaking changes",
      "matchUpdateTypes": ["major"],
      "addLabels": ["breaking-change"]
    }
  ]
}
```

The options used in the configuration above:

| Option                                                                                                                     | Description                                                                                                     |
| -------------------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------- |
| <nobr>[`schedule`](https://docs.renovatebot.com/configuration-options/#schedule){ target=_blank }</nobr>                   | Only create pull requests in the defined time frame, this bundles updates instead of interrupting you daily     |
| <nobr>[`minimumReleaseAge`](https://docs.renovatebot.com/configuration-options/#minimumreleaseage){ target=_blank }</nobr> | Waits a couple of days before proposing a new version, buggy releases are often fixed or retracted in this time |
| <nobr>[`pre-commit`](https://docs.renovatebot.com/modules/manager/pre-commit/){ target=_blank }</nobr>                     | The *pre-commit* manager is **disabled** by default and must be enabled explicitly                              |
| <nobr>[`packageRules`](https://docs.renovatebot.com/configuration-options/#packagerules){ target=_blank }</nobr>           | Rules which apply to a subset of dependencies, matched by manager, package name, update type, ...               |
| <nobr>[`groupName`](https://docs.renovatebot.com/configuration-options/#groupname){ target=_blank }</nobr>                 | Combines all matching updates into a single pull request                                                        |
| <nobr>[`automerge`](https://docs.renovatebot.com/configuration-options/#automerge){ target=_blank }</nobr>                 | Merges the pull request automatically if all checks of the CI pipeline succeed                                  |

All available options are described in the [configuration options](https://docs.renovatebot.com/configuration-options/){ target=_blank } documentation.

!!! info "ansible-core does not follow Semantic Versioning"
    The versions of *ansible-core* look like *SemVer*, but a **minor** update (e.g. `2.19` → `2.20`) is a major release, which removes deprecated features and may break your playbooks. Check the [porting guides](https://docs.ansible.com/ansible/latest/porting_guides/porting_guides.html){ target=_blank } before merging, the configuration above labels these updates as `breaking-change`.

!!! warning "Automerge only with a CI pipeline"
    <!-- markdownlint-disable-next-line MD052 -->
    **Only enable `automerge` if your repository has a CI pipeline with [linting][linting-ci-pipeline]{ data-preview } and [testing][ansible-testing]{ data-preview }!**  
    Without any checks, *Renovate* merges every update, even if it breaks your playbooks.

??? tip "Updates for a specific ansible-core version"
    Your project should use the same *ansible-core* version as your runtime environment (e.g. your Automation Platform or Execution Environment), newer versions of collections may also require a newer *ansible-core* version. Use [`allowedVersions`](https://docs.renovatebot.com/configuration-options/#allowedversions){ target=_blank } to restrict updates of *ansible-core* and collections:

    ```json
    {
      "packageRules": [
        {
          "matchManagers": ["pip_requirements"],
          "matchPackageNames": ["ansible-core"],
          "allowedVersions": "<2.20.0"
        },
        {
          "matchManagers": ["ansible-galaxy"],
          "matchPackageNames": ["community.general"],
          "allowedVersions": "<12.0.0"
        }
      ]
    }
    ```

### Execution Environment base image

The base image in the `execution-environment.yml` can be updated with a [*custom manager*](https://docs.renovatebot.com/modules/manager/regex/){ target=_blank } using a regular expression:

```json title="renovate.json"
{
  "customManagers": [
    {
      "customType": "regex",
      "description": "Update base image of Execution Environment definition files",
      "managerFilePatterns": ["/(^|/)execution-environment\\.ya?ml$/"],
      "matchStrings": ["base_image:\\s*\\n\\s*name:\\s*[\"']?(?<depName>[^\\s:\"']+):(?<currentValue>[^\\s\"']+)"],
      "datasourceTemplate": "docker"
    }
  ]
}
```

The regular expression matches the `name` key below the `base_image` key and extracts the image name and its tag:

```yaml title="execution-environment.yml"
---
version: 3

images:
  base_image:
    name: registry.example.com/ansible/ee-base:1.4.0
```

!!! info
    The base image must use a specific tag, an image using the `latest` tag can not be updated.  
    Images from registries with authentication, like *registry.redhat.io*, require [host rules](https://docs.renovatebot.com/configuration-options/#hostrules){ target=_blank } with credentials in your *Renovate* configuration.

### Validate configuration

Validate your configuration before committing it, *Renovate* provides a [validator](https://docs.renovatebot.com/config-validation/){ target=_blank }:

```bash
npx --yes --package renovate@latest -- renovate-config-validator --strict
```

!!! warning "Always use renovate@latest with npx"
    Without the version suffix, `npx` reuses an older *Renovate* version from its local cache, if one was ever installed. An outdated validator reports valid options of newer versions (e.g. `managerFilePatterns`) as errors.

Or use the official [*pre-commit* hook](https://github.com/renovatebot/pre-commit-hooks){ target=_blank }, which runs the same validator on every commit. With the `--strict` option, deprecated or renamed options are reported as errors as well:

```yaml title=".pre-commit-config.yaml"
repos:
  - repo: https://github.com/renovatebot/pre-commit-hooks
    rev: "44.199.0"
    hooks:
      - id: renovate-config-validator
        name: 🛠️ Check Renovate configuration
        args: [--strict]
```

## Renovate and semantic-release

If you are using [semantic-release](semantic-release.md){ data-preview }, *Renovate* [detects the Conventional Commits](https://docs.renovatebot.com/semantic-commits/){ target=_blank } in your repository history and prefixes the commit messages of its updates automatically, e.g. `chore(deps): update dependency ansible-lint to v26.10.1`.

Updates with the `chore` type do **not** trigger a release. For dependencies your consumers rely on, like the collections in the `galaxy.yml` of your collection, use the `fix` type with the [`semanticCommitType`](https://docs.renovatebot.com/configuration-options/#semanticcommittype){ target=_blank } option, so a new *patch* release is created:

```json title="renovate.json"
{
  "packageRules": [
    {
      "matchManagers": ["ansible-galaxy"],
      "semanticCommitType": "fix"
    }
  ]
}
```

!!! success
    Combining both tools gives you a fully automated workflow: *semantic-release* publishes a new version of your role or collection and *Renovate* proposes the update in every project using it.
