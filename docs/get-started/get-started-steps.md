---
description: How to get started with Ansible content development
---
# Get started

When starting a new automation project, you (and potentially together with your team!) will need to make a couple of initial decisions and prepare your project, before starting to develop the actual automation content.

## 1. Create Git project

Use version control and follow a basic Git workflow. Use Pre-Commit to enforce code formatting or run tests before a commit is made.

* [Configure Git][project-lifecycle-version-control] <!-- markdownlint-disable-line MD052 -->
* [Create, configure and use Pre-Commit][pre-commit] <!-- markdownlint-disable-line MD052 -->

## 2. Define naming scheme and where to put variables

Decide on a proper naming convention and stick to it.

* [Naming content](../ansible/project.md#filenames)
* [Variable storage](../ansible/variables.md#defining-variables)

## 3. Configure Ansible

Create a basic configuration file in your project root folder.

* [Project-specific Ansible configuration file][ansible-configuration] <!-- markdownlint-disable-line MD052 -->

## 4. Role or Collection

*Are you creating content which can be used by others or is the scope limited?*  
Collections are easier to consume than roles. Create multiple repositories for collections or roles and additional ones for playbooks and variables if useful.

* [Collection structure](../ansible/collections.md)
* [Roles structure](../ansible/roles.md)

## 5. Define inventory

Use a dynamic inventory source if possible, otherwise create a static inventory file with your target nodes.

* [Dynamic inventory](../ansible/inventory.md#dynamic-inventory)
* [Static inventory](../ansible/inventory.md#static-inventory)

## 6. Choose execution engine

*Content will be run in AAP later on?*  
Use **ansible-navigator** with **Execution Environment** from AAP (or create a custom one) during development on CLI.  
Otherwise stick to **ansible-core**.

* [Build Execution Environment](../ansible/installation.md#ansible-builder) and [run with ansible-navigator](../ansible/execution.md#execute-with-ansible-navigator)

## Final notes

!!! tip
    **Remember, these are only recommendations.** Use your own judgement and experiences made from previous projects.  
    **Embrace change!** Your project will evolve, if changes are useful for better readability or functionality, do it (after discussing with and consulting the rest of the team).

As an overall guidance for designing good automation content, consider the [Zen of Ansible](https://www.redhat.com/en/blog/the-zen-of-ansible){ target=_blank }.

### The Zen of Ansible

The 20 aphorisms for Ansible are opinions that can be debated and sometimes can be contradictory.
What matters is that they communicate a mindset for getting the most from Ansible and your automation.
Your Ansible automation content doesn't necessarily have to follow this guidance, but they're good ideas to keep in mind.

<div class="grid cards" markdown>

* :infinity: 20 aphorisms for Ansible

    ``` { .yaml linenums="1" .no-copy }
    Ansible is not Python. # (1)!
    YAML sucks for coding.
    Playbooks are not for programming.
    Ansible users are (most likely) not programmers.
    Clear is better than cluttered. # (2)!
    Concise is better than verbose.
    Simple is better than complex.
    Readability counts.
    Helping users get things done matters most. # (3)!
    User experience beats ideological purity.
    "Magic" conquers the manual. # (4)!
    When giving users options, use convention over configuration. # (5)!
    Declarative is better than imperative - most of the time. # (6)!
    Focus avoids complexity. # (7)!
    Complexity kills productivity.
    If the implementation is hard to explain, it's a bad idea. # (8)!
    Every shell command and UI interaction is an opportunity to automate. # (9)!
    Just because something works, doesn't mean it can't be improved. # (10)!
    Friction should be eliminated whenever possible.
    Automation is a journey that never ends. # (11)!
    ```

    1. **YAML sucks for coding.**  
       **Playbooks are not for programming.**  
       **Ansible users are (most probably) not programmers.**  
       These aphorisms are at the heart of why applying guidelines for a programming language to good Ansible automation content didn't seem right to me. As I said, it would give the wrong impression and would reinforce a mindset we don't recommend - that Ansible is a programming language for coding your playbooks.  
       These aphorisms are all saying the same thing in different ways - certainly the first 3. If you're trying to "write code" in your plays and roles, you're setting yourself up for failure. Ansible's YAML-based playbooks were never meant to be for programming.  
       So it bothers me when I see Python-isms bleeding into what Ansible users see and do. It may be natural and make sense if you write code in Python, but most Ansible users are not Pythonistas.
       So, it can be challenging and confusing when these isms are incorporated, thereby introducing friction that degrades their user experience and the value that Ansible provides.  
       By Ansible not being a programming language, all parts of your organization can contribute to automating your entire IT stack rather than relying on skill programmers to understand your operations to write and maintain code for it.  
       If you are a programmer creating Ansible modules and plugins, assume you are not the target audience for what you are developing and your target audience won't have the same skills and resources you possess.

    2. **Clear is better than cluttered. Concise is better than verbose. Simple is better than complex. Readability counts.**  
       These are really just interpretations of aphorisms in “The Zen of Python”. The last one is taken directly from it because you can't improve on perfection.  
       In the original Ansible best practices talk, we recommended users optimize for readability. This holds true even more so today. If done properly, your content can be the documentation of your workflow automation. Take the time to make your automation as clear and concise as possible.
       Iterate over what you create and always look for opportunities to simplify and clarify.  
       These aphorisms don't just apply to those writing playbooks and creating roles. If you are a module developer, think about how your work can assist users, be clear and concise, do things simply and just get things done.

    3. **Helping users get things done matters most. User experience beats ideological purity.**  
       Whether you are creating modules, plugins and collections or writing playbooks or designing a cross domain hybrid automation workflow – Ansible is for helping you get things done. Always consider and look to maximize the user experience.
       Don't get caught up and beholden to some strict interpretation of standards or ideological purity that shifts the burden on the end user.

    4. **"Magic" conquers the manual Arthur C. Clarke wrote, "Any sufficiently advanced technology is indistinguishable from magic."**  
       The "magic" in Ansible is its playbook engine and module system. It is how Ansible provides powerful and flexible capabilities in a straightforward and accessible way by abstracting users from all of the complex implementation details that lie beneath.
       This frees users from doing time consuming and error prone manual operations or writing brittle one-off scripts and code, enabling them the time to put their valuable expertise to use where it is needed.  
       Design automation that amazes users can make difficult or tedious tasks easy and almost effortless. Look to provide powerful time saving capabilities that are quick to deploy and utilize them to get things done.

    5. **When giving users options, use convention over configuration.**  
       I am a big proponent of convention over configuration and don't think it gets enough consideration in the Ansible community.
       Convention over configuration is a design paradigm that attempts to decrease the number of decisions that a developer is required to make without necessarily losing flexibility so they don't have to repeat themselves. It was popularized by Ruby on Rails.  
       A playbook developer utilizing your work should only need to specify unique and unconventional aspects of their automation tasks and workflows and no more. Look to reduce the number of decisions and implementation details a user needs to make.
       Take the time to handle the most common use cases for them. Look to provide as many sensible defaults with modules, plugins and roles as possible. Optimize for users to get things done quickly.

    6. **Declarative is better than imperative - most of the time.**  
       This aphorism is particularly for Ansible Content Collection developers. Ansible is a desired state engine by design. Think declaratively first. If there truly is no way to design something declaratively, then use imperative (procedural) means.  
       Declarative means that configuration is guaranteed by a set of facts instead of by a set of instructions, for example, “there should be 10 RHEL servers”, rather than "depending on how many RHEL servers are running, start/stop servers until you have 10, and tell me if it worked or not".  
       This aphorism is an example of the “user experience beats ideological purity” aphorism in practice. Rather than strictly adhering to a declarative approach to automation, Ansible incorporates declarative and imperative means.
       This mix offers you the flexibility to focus on what you need to do, rather than strictly adhere to one paradigm.

    7. **Focus avoids complexity. Complexity kills productivity.**  
       Remember that complexity kills productivity. The Ansible team at Red Hat really means it and believes that. That's not just a marketing slogan. Automation can crush complexity and give you the one thing you can't get enough of ⎯ time.  
       Follow Linux principles of doing one thing, and one thing well. Keep roles and playbooks focused on a specific purpose. Multiple simple ones are better than having a huge single playbook full of conditionals and “programming” that Ansible is not well suited for.  
       We strive to reduce complexity in how we've designed Ansible and encourage you to do the same. Strive for simplification in what you automate.

    8. **If the implementation is hard to explain, it's a bad idea.**  
       This aphorism, like "readability counts", is also taken directly from "The Zen of Python" because you cannot improve upon perfection.  
       In his essay on Literate Programming, Charles Knuth wrote, "Instead of imagining that our main task is to instruct a computer what to do, let us concentrate rather on explaining to human beings what we want a computer to do."
       So it goes that if you cannot explain or document your implementation easily, then it's a bad idea that needs to be rethought or scrapped. If it is hard to explain, what chance do others have of understanding it, using it and debugging it?
       Kernighan's Law says "Debugging is twice as hard as writing the code in the first place. Therefore, if you write the code as cleverly as possible, you are, by definition, not smart enough to debug it."  
       Ansible is designed for how real people think and work. Recall earlier when I said Ansible Playbooks are human readable automation with no special coding skills needed. Take advantage of that.
       Then, if you are having trouble explaining what you are trying to do, pause and re-consider your implementation and the process you are trying to automate. How can I make it easier to explain? Can my process be improved or streamlined? How can I simplify and clarify?
       Can I break it down into smaller more focused parts and iterate over this?  
       This will help you identify a bad idea sooner and avoid the types of friction that will slow down you and your organization over time.

    9. **Every shell command and UI interaction is an opportunity to automate.**  
       This aphorism comes from my personal experience talking about Ansible and automation for many years. Sometimes I am asked what they should automate. Other times, I am challenged that an automation tool like Ansible is unnecessary or does not apply to what they are doing.
       No matter if we were talking about RHEL, Windows, networking infrastructure, security, edge devices, or cloud services, my response has essentially been the same over the years. I have repeated it so often, that I have jokingly formulated the point into my own theorem on automation.
       So call it "Appnel's Theorem on Automation" if you will.  
       If you are wondering what should be automated, look for anything anyone is typing into a Linux shell and clicking through in a user interface. Then ask yourself "is this something that can be automated?" Then ask "what is the value of automating this?"
       Most Ansible modules wrap command line tools or use the same APIs behind UIs.  
       Given a sufficient number of things to automate is identified, start with those that cause the most pain and those that you can get done quickly. Remember you want to create a virtuous cycle of releasing reliability, feedback and building trust across your organization.
       Showing progress and business value quickly will help do that.

    10. **Just because something works, doesn't mean it can't be improved. Friction should be eliminated whenever possible. Just because something works, doesn't mean it can't be improved. Friction should be eliminated whenever possible.**  
        This first aphorism just so happens to be a quote from the movie Black Panther, and it elegantly expresses some important wisdom when it comes to Ansible automation.  
        Always iterate and adapt to real world feedback from your operations. Optimize readability. Continue to find ways to simplify and reduce friction in your organization and its processes.
        As changes are introduced into your environments and IT policies over time, they will create new friction and pain points. They will also create new opportunities to apply your automation practices to eliminate them.

    11. **A never ending story...**  
        Heraclitus, a Greek philosopher, said "change is the only constant in life. Nothing endures but change."  
        Anyone who has been around the IT industry for any length of time knows there is constant change. This is why it is so vital to be agile and prepared to respond to ongoing change, innovation and business demands quickly and reliably.  
        Automation is not a destination. It is a practice. It is a culture, a mindset and an attitude. Automation is a continuous process of feedback and learning and adapting to change and improving upon what you did before.  
        Automation creates opportunities and we at Red Hat see opportunities for automation everywhere.  
        So the question I pose to you is: Where will your automation journey lead you?

</div>
