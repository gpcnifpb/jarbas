# How to start the environment

## Choose
First of all, there are 2 types of environments. One is just to have a proper ShellScript environment to code.
And the other one provides a full scenario to run tests (attacks and monitoring).

- DevEnv
  - Uses only one VirtualMachine
  - Just to makes use of Bash

- Full DevEnv
  - Uses 5 VirtualMachines
    - Master (J.A.R.B.A.S. script)
    - Atacker
    - Client
    - Atacked
    - Monitored

## Rename and start

Now, rename the "Vagrantfile-<EnvType>" desired to just "Vagrantfile". And run the command:
```Bash
vagrant up
```
