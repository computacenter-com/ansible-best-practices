---
icon: lucide/text-search
---

# Logging

By default, Ansible sends output about plays, tasks, and module arguments to *stdout* on the control node, no log file is written.  
This section describes different options to enable logging.

!!! tip
    **Add your log files or folders to `.gitignore`!**  
    In most cases those files to not need to be version-controlled.

## Protecting sensitive data from logging

Most modules obfuscate passwords, if you save Ansible output to a log, you **may** expose any secret data in your Ansible output.  
To keep sensitive values out of your logs, mark tasks that expose them with the `no_log: true` attribute.  
