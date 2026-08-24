---
status: new
icon: lucide/file-pen-line
---

# Ansible Sign

Ansible Sign is a utility for signing and verifying Ansible automation content which can be used to secure workflows and pipelines for trusted automation content.
For Ansible content developers, the primary way of using `ansible-sign` is through the command-line interface that comes with it.  
The CLI utility aims to make it easy to use cryptographic technology like GPG to validate that specified files within a project have not been tampered with in any way.

## Installation

Ansible Sign is installed through `pipx` or `pip3`.

=== "pipx"

    ``` bash
    pipx install ansible-sign
    ```

=== "pip3"

    ``` bash
    pip3 install ansible-sign
    ```

## Create GPG key

Verify if a keypair already exists.

```bash
gpg --list-secret-keys
```

For a new key, use the following command:

```bash
gpg --full-generate-key
```

A complete rundown of the GPG key creation process is well documented in this [Red Hat Blog article](https://www.redhat.com/en/blog/creating-gpg-keypairs){:target="_blank"}.

## Prepare project for signing

Signing Ansible content requires a file that tells `ansible-sign` which files to protect. This file must be called `MANIFEST.in` and live in the project root directory.

!!! quote ""

    ``` mermaid
    ---
    config:
      treeView:
        rowIndent: 20
        defaultIconPack: vscode-icons
        showIcons: true
        filenameIcons:
          inventory.ini: file-type-config
          .gitignore: file-type-git
          grafana.repo: file-type-config
          .pre-commit-config.yaml: file-type-precommit
          requirements.txt: file-type-pypi
        extensionIcons:
          .cfg: file-type-config
          .md: file-type-markdown
          .yml: file-type-light-yaml-official
    ---
    treeView-beta
    ├── .gitignore
    ├── .pre-commit-config.yaml
    ├── MANIFEST.in :::highlight icon(file-type-manifest)
    ├── README.md
    ├── ansible.cfg
    ├── groups_vars/
    │   └── all/
    │       ├── all.yml
    │       └── grafana.yml
    ├── inventory.ini
    ├── main.yml
    ├── requirements.txt
    ├── requirements.yml
    └── roles/
        └── grafana/
            ├── defaults/
            │   └── main.yml
            ├── files/
            │   └── grafana.repo
            ├── handlers/
            │   └── main.yml
            └── tasks/
                ├── configuration.yml
                ├── installation.yml
                └── main.yml
    ```

The content is protected from tampering by taking checksums (sha256) of all of the secured files in the project (files referenced in `MANIFEST.in`), compiling those into a checksum manifest file, and then finally signing that manifest file.

!!! info inline end
    **Commands are processed in the order they appear in the file!**

``` text title="MANIFEST.in"
include inventory.ini .pre-commit-config.yaml main.yml
recursive-include group_vars *.yml
graft roles
```

Internally, `ansible-sign` makes use of the `distlib.manifest` module of Python’s distlib library.
Take a look at the [`MANIFEST.in` explanation in the Python Packaging User Guide](https://setuptools.pypa.io/en/latest/userguide/miscellaneous.html){:target="_blank"} for additional information.

The commands used in the `MANIFEST.in` file are:

| Command                                                    | Description                                                                                                             |
| ---------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------- |
| <nobr>`include pat1 pat2 ...`</nobr>                       | Add all files matching any of the listed patterns (Files must be given as paths relative to the root of the project)    |
| <nobr>`exclude pat1 pat2 ...`</nobr>                       | Remove all files matching any of the listed patterns (Files must be given as paths relative to the root of the project) |
| <nobr>`recursive-include dir-pattern pat1 pat2 ...`</nobr> | Add all files under directories matching `dir-pattern` that match any of the listed patterns                            |
| <nobr>`recursive-exclude dir-pattern pat1 pat2 ...`</nobr> | Remove all files under directories matching `dir-pattern` that match any of the listed patterns                         |
| <nobr>`global-include pat1 pat2 ...`</nobr>                | Add all files anywhere in the source tree matching any of the listed patterns                                           |
| <nobr>`global-exclude pat1 pat2 ...`</nobr>                | Remove all files anywhere in the source tree matching any of the listed patterns                                        |
| <nobr>`graft dir-pattern`</nobr>                           | Add all files under directories matching `dir-pattern`                                                                  |
| <nobr>`prune dir-pattern`</nobr>                           | Remove all files under directories matching `dir-pattern`                                                               |

Patterns are glob-style patterns and directory patterns are processed relative to the root of the project directory. Make use of the following if necessary:

* `*` matches zero or more regular filename characters
* `?` matches a single regular filename character
* `[chars]` matches any one of the characters between the square brackets, may contain character ranges, e.g., `[a-z]` or `[a-fA-F0-9]`
* `**` matching zero or more characters including forward slash, backslash, and colon

## Sign content

Now, **sign** the project from your project root directory:

!!! info
    **By default, the first usable key in the user's keyring is used!**  
    For a specific secret key, use the `--fingerprint` option.

```bash
ansible-sign project gpg-sign .
```

If the secret key is password-protected, GnuPG will automatically pop up a dialog.

!!! example "Output"

    ```{ .bash .no-copy}
    $ ansible-sign project gpg-sign .
    [OK   ] GPG signing successful!
    [NOTE ] Checksum manifest: ./.ansible-sign/sha256sum.txt
    [NOTE ] GPG summary: signature created
    ```

A new folder containing two files was created

!!! quote ""

    ``` mermaid
    ---
    config:
      treeView:
        rowIndent: 20
        defaultIconPack: vscode-icons
        showIcons: true
        filenameIcons:
          sha256sum.txt: file-type-text
          sha256sum.txt.sig: file-type-key
    ---
    treeView-beta
    .ansible-sign/
    ├── sha256sum.txt ## Checksum manifest with SHA256 for every file
    └── sha256sum.txt.sig ## GPG signature for checksum manifest
    ```

```{ .text .no-copy title="sha256sum.txt" }
77d2e8d2cb1c1c0d68f5a3f256de20e2afbdc80fe9d2580151fbaf042949b7f7  .gitignore
ce7a7da7857d62841639e93c33f22d6373ae2dba959478c97591937e6b3719c5  .pre-commit-config.yaml
03b458710c614ea4dca421d4b1eb173d0ce04c602a2578c693705ca4e43bd5b6  MANIFEST.in
e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855  README.md
e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855  group_vars/all/all.yml
e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855  group_vars/all/grafana.yml
c50ddecfa58b0f435fd77536837057de4b4fe001b0c82f724719e549421aeb08  inventory.ini
cf989136ddc2235d0d24b50f8ae163677e7bca64aebd93e81b1c93854938f68b  main.yml
898d3c2a0c84ddfadd19b686fb2bcd6b34970740737fb4e524626c7c18627ff0  roles/grafana/defaults/main.yml
f3d7d343ac2c2f878658c721eafda36d589b293e005a4f8515afaf9d767d8749  roles/grafana/files/grafana.repo
e355692d2bb0c72c573c2fb43f5be017c2438f7d2f184a02fb9cf13a13fda289  roles/grafana/handlers/main.yml
6bf11765269f68eac12d93af430867175c3be6c7fe1baa42a994264f1e76990b  roles/grafana/tasks/configuration.yml
d5099415891899fe65562d61026c8f09a689445b3e5a2d0295af95fd1acfd708  roles/grafana/tasks/installation.yml
f1e2553a7ee6a6b91323b72bfb6ee1748603f6ded053668d45d74e436d2ad010  roles/grafana/tasks/main.yml
```

When signing a project using GPG, the environment variable `ANSIBLE_SIGN_GPG_PASSPHRASE` can be set to the passphrase of the signing key which can be injected (and masked/secured) in a CI pipeline.
Take a look at the [ansible-sign documentation](https://docs.ansible.com/projects/sign/en/latest/rundown.html#notes-about-automation){:target="_blank"} for additional information.

## Verify content

To verify that a signed Ansible project has not been altered, use the `gpg-verify` argument:

```bash
ansible-sign project gpg-verify .
```

This checks that both the signature is valid and that the checksums of the files match what the checksum manifest says they should be.

<div class="grid" markdown>

!!! success "Output when project verification succeeds"

    ```{ .bash .no-copy }
    $ ansible-sign project gpg-verify .
    [OK   ] GPG signature verification succeeded.
    [OK   ] Checksum validation succeeded.
    ```

!!! failure "Output when project files have been altered"

    ```{ .bash .no-copy }
    $ ansible-sign project gpg-verify .
    [OK   ] GPG signature verification succeeded.
    [ERROR] Checksum validation failed.
    [ERROR] Checksum mismatch: roles/grafana/files/grafana.repo
    ```

</div>
