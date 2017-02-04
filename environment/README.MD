# How to start the environment

## Understand the environment

This is a multi-machine Vagrant environment, each has it's own purpose.

- Master (J.A.R.B.A.S. script)
  - Controls the others.
- Attacker
  - Flood the attacked
- Client
  - Try legitmate connections
- Attacked
  - The loud neighboor
- Monitored
  - The one to isolate

## Start all or just one

All of them
```Bash
vagrant up
```

One of them
```Bash
vagrant up Master
vagrant halt Master
```

Watchout because this is case senstive so Master != master
