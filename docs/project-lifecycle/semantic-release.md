---
icon: lucide/tag
description: How to version and release your Ansible content automatically with semantic-release
status: new
---

# Release Management

Ansible content that is consumed by others, like collections, roles or even playbook projects which are executed by the Automation Platform, should be **versioned**. A version tells the consumer *what* changed and *if* an update is safe to install.  
Deciding on the next version number, writing the changelog and creating the Git tag by hand is tedious and error-prone. [*semantic-release*](https://semantic-release.org/){ target=_blank } automates the whole release workflow: it determines the next version number from your commit messages, generates the release notes and publishes the release.

## Semantic Versioning

*semantic-release* uses [Semantic Versioning](https://semver.org/){ target=_blank } (SemVer). A version number has the format `MAJOR.MINOR.PATCH`, every part has a specific meaning:

| Part      | Increment when...                                     | Example           |
| --------- | ----------------------------------------------------- | ----------------- |
| **MAJOR** | you make incompatible changes (breaking changes)      | `1.4.2` → `2.0.0` |
| **MINOR** | you add functionality in a backward compatible manner | `1.4.2` → `1.5.0` |
| **PATCH** | you make backward compatible bug fixes                | `1.4.2` → `1.4.3` |

Where the version of your Ansible content lives depends on the content type:

* **Collections** - the `version` key in the `galaxy.yml`, the version is also part of the collection tarball name.
* **Roles** - a Git tag, consumers reference the tag in their `requirements.yml` (e.g. `version: v1.4.2`).
* **Playbook projects** - a Git tag, e.g. to reference a specific state of the project in an Automation Platform project.

!!! tip
    **Always pin versions of collections and roles in the `requirements.yml` of your project!**  
    With versioned dependencies you control *when* an update is applied, tools like [Renovate](renovate.md){ data-preview } can propose these updates automatically.

## Conventional Commits

*semantic-release* does not guess, it analyzes the commit messages since the last release. Therefore, all commit messages must follow the [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/){ target=_blank } specification:

```{ .text .no-copy }
<type>[optional scope]: <description>

[optional body]

[optional footer(s)]
```

The specification itself only defines the `feat` and `fix` types and breaking changes, all other types are optional. The commonly used types below are taken from [@commitlint/config-conventional](https://github.com/conventional-changelog/commitlint/tree/master/%40commitlint/config-conventional){ target=_blank } (based on the *Angular* convention).  
The *type* of the commit decides which part of the version is incremented, the release column shows the default rules of *semantic-release*:

| Type                                                                     | Description                                        | Release      |
| ------------------------------------------------------------------------ | -------------------------------------------------- | ------------ |
| `fix`                                                                    | A bug fix                                          | **PATCH**    |
| `perf`                                                                   | A change that improves performance                 | **PATCH**    |
| `revert`                                                                 | Reverts a previous commit                          | **PATCH**    |
| `feat`                                                                   | A new feature, e.g. a new role, module or variable | **MINOR**    |
| Any type with `!` (e.g. `feat!`) or a `BREAKING CHANGE:` footer          | A change that breaks backward compatibility        | **MAJOR**    |
| <nobr>`build`, `chore`, `ci`, `docs`, `refactor`, `style`, `test`</nobr> | Changes that do not affect the consumer            | *No release* |

Some examples for commit messages in an Ansible collection:

```{ .bash .no-copy }
git commit -m "fix(postgres): ensure service is restarted after config change"
git commit -m "feat(postgres): add variable to configure max_connections"
git commit -m "docs: add example playbook to README"
git commit -m "feat(postgres)!: rename variable postgres_port to postgres_listen_port"
```

The optional *scope* in parentheses should be the name of the role, module or plugin that is affected, this makes the generated release notes much more readable.

!!! warning "Breaking changes in Ansible content"
    Renaming or removing a role variable, changing a default value or raising the minimum *ansible-core* version are **breaking changes**!  
    Consumers of your content may need to adjust their playbooks or inventory, mark these commits with an exclamation mark (`feat!:`) or a `BREAKING CHANGE:` footer.

!!! info
    The [Version Control](git.md#feature-request){ data-preview } section shows commit messages in free form. If you adopt *semantic-release* for your project, **all** contributors must use Conventional Commits, otherwise changes are missing in the release notes or no release is created at all.

### Enforce commit message format

Ensure that every commit message follows the specification with a [pre-commit](git.md#pre-commit){ data-preview } hook. The [conventional-pre-commit](https://github.com/compilerla/conventional-pre-commit){ target=_blank } hook is written in Python, no *Node.js* installation is necessary.

Add the hook to your `.pre-commit-config.yaml`:

```yaml title=".pre-commit-config.yaml"
repos:
  - repo: https://github.com/compilerla/conventional-pre-commit
    rev: v4.4.0
    hooks:
      - id: conventional-pre-commit
        name: 📝 Check commit message follows Conventional Commits
        stages: [commit-msg]
```

The hook runs in the `commit-msg` stage, which is **not** installed by default. Install it explicitly:

```bash
pre-commit install --hook-type commit-msg
```

A commit with a wrong message is now rejected:

```{ .bash .no-copy }
$ git commit -m "Added tasks to configure Postgres High-Availability."
📝 Check commit message follows Conventional Commits.......................Failed
- hook id: conventional-pre-commit
- exit code: 1

[Bad commit message] >> Added tasks to configure Postgres High-Availability.
Your commit message does not follow Conventional Commits formatting
https://www.conventionalcommits.org/

Use the --verbose arg for more information
```

!!! tip
    Add the same check as a job in your CI pipeline for merge requests, Git hooks can be skipped locally with `--no-verify`.

## Installation

*semantic-release* is a *Node.js* application and is published as an *npm* package, a current [*Node.js* LTS version](https://nodejs.org/en/about/previous-releases){ target=_blank } is required.  
Most of the functionality is provided by [plugins](https://semantic-release.org/extending/plugins-list){ target=_blank }, which need to be installed alongside *semantic-release*.

```bash
npm install --no-save semantic-release @semantic-release/changelog @semantic-release/exec @semantic-release/git conventional-changelog-conventionalcommits@9
```

!!! info
    Your Ansible project does not need a `package.json`, the `--no-save` option installs the packages without creating one. Install all packages with a **single** command, a second `npm install --no-save` removes the packages installed before.  
    *semantic-release* is designed to run in a [CI pipeline](#ci-pipeline), install it on your development machine only to [test your configuration](#test-configuration).

!!! warning "Pin conventional-changelog-conventionalcommits to version 9"
    Version 10 of the `conventional-changelog-conventionalcommits` package requires a newer changelog writer than the one used by the `@semantic-release/release-notes-generator` plugin, the release fails with the error `Missing helper: "conventional-changelog-conventionalcommits requires conventional-changelog-writer@9 or newer"`.  
    Use version 9 until the plugin supports the newer writer.

## Configuration

*semantic-release* is configured with a [`.releaserc.json`](https://semantic-release.org/usage/configuration){ target=_blank } file in the project root directory. The configuration defines the release branch and the plugins that are executed, plugins are executed in the order they are defined.

=== "Collection"

    ```json title=".releaserc.json"
    {
      "branches": ["main"],
      "plugins": [
        ["@semantic-release/commit-analyzer", { "preset": "conventionalcommits" }],
        ["@semantic-release/release-notes-generator", { "preset": "conventionalcommits" }],
        ["@semantic-release/changelog", { "changelogFile": "CHANGELOG.md" }],
        [
          "@semantic-release/exec",
          {
            "prepareCmd": "sed -i 's/^version: .*/version: ${nextRelease.version}/' galaxy.yml",
            "publishCmd": "ansible-galaxy collection build --force && ansible-galaxy collection publish *-${nextRelease.version}.tar.gz --api-key $GALAXY_API_KEY"
          }
        ],
        [
          "@semantic-release/git",
          {
            "assets": ["galaxy.yml", "CHANGELOG.md"],
            "message": "chore(release): ${nextRelease.version} [skip ci]\n\n${nextRelease.notes}"
          }
        ],
        "@semantic-release/github"
      ]
    }
    ```

=== "Role or playbook project"

    ```json title=".releaserc.json"
    {
      "branches": ["main"],
      "plugins": [
        ["@semantic-release/commit-analyzer", { "preset": "conventionalcommits" }],
        ["@semantic-release/release-notes-generator", { "preset": "conventionalcommits" }],
        ["@semantic-release/changelog", { "changelogFile": "CHANGELOG.md" }],
        [
          "@semantic-release/git",
          {
            "assets": ["CHANGELOG.md"],
            "message": "chore(release): ${nextRelease.version} [skip ci]\n\n${nextRelease.notes}"
          }
        ],
        "@semantic-release/github"
      ]
    }
    ```

The plugins used in the configuration above:

| Plugin                                                                                                                                   | Description                                                                                                         |
| ---------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------- |
| <nobr>[`@semantic-release/commit-analyzer`](https://github.com/semantic-release/commit-analyzer){ target=_blank }</nobr>                 | Analyzes the commit messages and determines the next version                                                        |
| <nobr>[`@semantic-release/release-notes-generator`](https://github.com/semantic-release/release-notes-generator){ target=_blank }</nobr> | Generates the release notes from the commit messages                                                                |
| <nobr>[`@semantic-release/changelog`](https://github.com/semantic-release/changelog){ target=_blank }</nobr>                             | Writes the release notes to the `CHANGELOG.md` file                                                                 |
| <nobr>[`@semantic-release/exec`](https://github.com/semantic-release/exec){ target=_blank }</nobr>                                       | Executes custom shell commands, used to set the version in the `galaxy.yml` and to build and publish the collection |
| <nobr>[`@semantic-release/git`](https://github.com/semantic-release/git){ target=_blank }</nobr>                                         | Commits the changed files (`galaxy.yml`, `CHANGELOG.md`) back to the repository                                     |
| <nobr>[`@semantic-release/github`](https://github.com/semantic-release/github){ target=_blank }</nobr>                                   | Creates the Git tag and a GitHub release with the release notes                                                     |

!!! tip "Use the conventionalcommits preset"
    The default preset of the analyzer follows the *Angular* commit convention, which does not understand the exclamation mark (`feat!:`). Such a commit does not trigger a release **at all**, only the `BREAKING CHANGE:` footer is detected.  
    The `conventionalcommits` preset (provided by the [`conventional-changelog-conventionalcommits`](https://github.com/conventional-changelog/conventional-changelog/tree/master/packages/conventional-changelog-conventionalcommits){ target=_blank } package) implements the full specification.

??? tip "Publish to a private Automation Hub"
    Use the `--server` option of `ansible-galaxy` to [publish](https://docs.ansible.com/ansible/latest/dev_guide/developing_collections_distributing.html){ target=_blank } your collection to a private Automation Hub instead of Ansible Galaxy:

    ```bash
    ansible-galaxy collection publish *-${nextRelease.version}.tar.gz --server https://hub.example.com/api/galaxy/content/inbound-<namespace>/ --api-key $GALAXY_API_KEY
    ```

??? tip "Using GitLab"
    Replace the `@semantic-release/github` plugin with the [`@semantic-release/gitlab`](https://github.com/semantic-release/gitlab){ target=_blank } plugin, this creates a GitLab release instead. The plugin must be installed additionally.  
    When running in GitLab CI, the URL of a self-hosted GitLab instance is detected automatically.

!!! warning "Protected branches"
    The `@semantic-release/git` plugin pushes a commit to the release branch. If your *main* branch is protected (which it should be!), the token used by *semantic-release* must be allowed to push to it.  
    If this is not possible in your environment, remove the `@semantic-release/git` plugin. The release, tag and changelog are still created, but the `galaxy.yml` and `CHANGELOG.md` in your repository are not updated.

!!! danger "Exclude node_modules from the collection"
    The *npm* packages are installed into the `node_modules` folder of your project directory. `ansible-galaxy collection build` packages **everything** in the collection directory, without an exclusion the collection tarball grows from a couple of KB to more than 10 MB!  
    Add the folder to the `build_ignore` list in your `galaxy.yml`:

    ```yaml title="galaxy.yml"
    build_ignore:
      - node_modules
    ```

### Test configuration

*semantic-release* provides a [*dry-run*](https://semantic-release.org/usage/configuration#dryrun){ target=_blank } mode, which outputs the next version and the release notes **without** creating a release. Run it locally from your project root directory, after [installing](#installation) the packages. A token with **push** permission to your repository is necessary, as *semantic-release* verifies that it is allowed to push the release tag:

```bash
GITHUB_TOKEN=<your-token> npx semantic-release --dry-run --no-ci
```

??? example "Example output"

    ```{ .bash .no-copy }
    $ GITHUB_TOKEN=<your-token> npx semantic-release --dry-run --no-ci
    [6:43:35 PM] [semantic-release] › ℹ  Running semantic-release version 25.0.9
    [6:43:35 PM] [semantic-release] › ⚠  Run automated release from branch main on repository https://github.com/example/postgres.git in dry-run mode
    [6:43:35 PM] [semantic-release] › ✔  Allowed to push to the Git repository
    [6:43:35 PM] [semantic-release] › ℹ  Found git tag v1.0.0 associated with version 1.0.0 on branch main
    [6:43:35 PM] [semantic-release] › ℹ  Found 3 commits since last release
    [6:43:35 PM] [semantic-release] [@semantic-release/commit-analyzer] › ℹ  Analyzing commit: feat(postgres): add variable to configure max_connections
    [6:43:35 PM] [semantic-release] [@semantic-release/commit-analyzer] › ℹ  The release type for the commit is minor
    [6:43:35 PM] [semantic-release] [@semantic-release/commit-analyzer] › ℹ  Analyzing commit: fix(postgres): ensure service is restarted after config change
    [6:43:35 PM] [semantic-release] [@semantic-release/commit-analyzer] › ℹ  The release type for the commit is patch
    [6:43:35 PM] [semantic-release] [@semantic-release/commit-analyzer] › ℹ  Analyzing commit: docs: add README
    [6:43:35 PM] [semantic-release] [@semantic-release/commit-analyzer] › ℹ  The commit should not trigger a release
    [6:43:35 PM] [semantic-release] [@semantic-release/commit-analyzer] › ℹ  Analysis of 3 commits complete: minor release
    [6:43:35 PM] [semantic-release] › ℹ  The next release version is 1.1.0
    [...output cut for readability...]
    [6:43:35 PM] [semantic-release] › ⚠  Skip v1.1.0 tag creation in dry-run mode
    [6:43:35 PM] [semantic-release] › ✔  Published release 1.1.0 on default channel
    [6:43:35 PM] [semantic-release] › ℹ  Release note for version 1.1.0:
    ## 1.1.0 (https://github.com/example/postgres/compare/v1.0.0...v1.1.0) (2026-11-10)

    ### Features

        * **postgres:** add variable to configure max_connections (d631013)

    ### Bug Fixes

        * **postgres:** ensure service is restarted after config change (9f7f52b)
    ```

## Release workflow

Every merge to the *main* branch triggers *semantic-release*, which decides on its own if a new release is necessary. In the example below, the merge of the *docs* commit does not trigger a release, the *fix* commit triggers a *patch* release and the *feat* commit a *minor* release.

```{ .mermaid }
gitGraph
   commit id: "feat: initial release" tag: "v1.0.0"
   branch feature
   checkout feature
   commit id: "docs: add README"
   checkout main
   merge feature
   branch bugfix
   checkout bugfix
   commit id: "fix: restart service"
   checkout main
   merge bugfix tag: "v1.0.1"
   branch feature2
   checkout feature2
   commit id: "feat: add variable"
   checkout main
   merge feature2 tag: "v1.1.0"
```

!!! info
    If you are using a *dev* branch as described in the [branching concept](git.md#branching-concept){ data-preview }, only the *main* branch should be configured as a [release branch](https://semantic-release.org/usage/configuration#branches){ target=_blank }. All changes collected in the *dev* branch are released together when merging into *main*.

## CI Pipeline

*semantic-release* needs the **complete** Git history to find the last release, ensure the pipeline does not use a *shallow clone*.  
Take a look at the [CI configuration](https://semantic-release.org/usage/ci-configuration){ target=_blank } documentation for authentication and further options.

=== "GitHub Actions"

    ```yaml title=".github/workflows/release.yml"
    name: Release
    on:
      push:
        branches:
          - main
    permissions:
      contents: read
    jobs:
      release:
        name: Create release with semantic-release
        runs-on: ubuntu-latest
        permissions:
          contents: write
          issues: write
          pull-requests: write
        steps:
          - name: Checkout repository
            uses: actions/checkout@v7
            with:
              fetch-depth: 0
              persist-credentials: false
          - name: Setup Node.js
            uses: actions/setup-node@v7
            with:
              node-version: lts/*
          - name: Install ansible-core
            run: pipx install ansible-core
          - name: Install semantic-release and plugins
            run: >-
              npm install --no-save semantic-release @semantic-release/changelog
              @semantic-release/exec @semantic-release/git conventional-changelog-conventionalcommits@9
          - name: Create release
            env:
              GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
              GALAXY_API_KEY: ${{ secrets.GALAXY_API_KEY }}
            run: npx semantic-release
    ```

    The official [GitHub Actions recipe](https://semantic-release.org/recipes/ci-configurations/github-actions){ target=_blank } shows additional options.

=== "GitLab CI"

    ```yaml title=".gitlab-ci.yml"
    stages:
      - release

    release:
      stage: release
      image: node:lts
      rules:
        - if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH
      variables:
        GIT_DEPTH: 0
      before_script:
        - apt-get update && apt-get install -y --no-install-recommends pipx
        - pipx install ansible-core
        - export PATH="$HOME/.local/bin:$PATH"
        - >-
          npm install --no-save semantic-release @semantic-release/changelog
          @semantic-release/exec @semantic-release/git @semantic-release/gitlab
          conventional-changelog-conventionalcommits@9
      script:
        - npx semantic-release
    ```

    Create a [*Project Access Token*](https://docs.gitlab.com/user/project/settings/project_access_tokens/){ target=_blank } with the `api` and `write_repository` scopes and store it as a masked CI/CD variable named `GITLAB_TOKEN`. The official [GitLab CI recipe](https://semantic-release.org/recipes/ci-configurations/gitlab-ci/){ target=_blank } shows additional options.

The `ansible-core` installation is only necessary for collections, as `ansible-galaxy` is used to build and publish the collection. Store the API key for Ansible Galaxy (or your private Automation Hub) as a secret named `GALAXY_API_KEY`.

!!! success
    From now on, every merge to *main* is analyzed and released automatically, including release notes and changelog!

## semantic-release vs. antsibull-changelog

The Ansible community uses [antsibull-changelog](https://docs.ansible.com/projects/antsibull-changelog/){ target=_blank } for collections. Instead of analyzing commit messages, every change adds a small YAML file (a *changelog fragment*) to the `changelogs/fragments/` folder of the collection, the changelog is generated from these fragments.

| Aspect               | semantic-release                         | antsibull-changelog                                     |
| -------------------- | ---------------------------------------- | ------------------------------------------------------- |
| Source for changelog | Commit messages                          | Changelog fragments                                     |
| Next version         | Determined automatically                 | Chosen manually by the maintainer                       |
| Release              | Fully automated in the CI pipeline       | Manual, `antsibull-changelog release`                   |
| Changelog format     | `CHANGELOG.md`                           | `changelogs/changelog.yaml` and `CHANGELOG.md`/`.rst`   |
| Runtime              | *Node.js*                                | Python                                                  |
| Suitable for         | Internal collections, roles and projects | Collections included in the *ansible* community package |

!!! tip
    **Collections that should be included in the *ansible* community package must use *antsibull-changelog*!**  
    For your internal collections, roles and playbook projects, *semantic-release* provides a fully automated release workflow without the need of maintaining changelog fragments.
