# Daml Interface Demonstration

This repository contains an simple example illustrating usage of Daml
interfaces to abstract the differences between different versions of
the same package. It contains two versions of a test Daml model, a common interface
modulye, and scripts that automate the process of building the models,
starting a local test ledger populated with test data, and then
executing the upgrade.

***This is currently a work in progress. Querying interfaces from the
Python code is not currently implemented.***

## Prerequisite Software

There isn't much software required to make this work, but there are
a few packages you'll need to have installed.

1. [Daml SDK](https://docs.daml.com/getting-started/installation.html)
2. [jq](https://jqlang.github.io/jq/) - (Best installed through whatever
   package manager you use for your OS.)
3. [Python](https://www.python.org) - (Best installed through whatever
   package manager you use for your OS.)
4. [Dazl](https://github.com/digital-asset/dazl-client) - The Digital
   Asset ledger client library for Python. This will be installed as part
   of `build.sh`, as described below.

## Running Locally

1. Run `./build.sh` to build the base Daml models.
2. Run `./start-ledger.sh` to start a local sandbox ledger. This will
   also populate the ledger with test contracts via a script defined
   in `scripts`.
3. Run `./run-main.sh` to launch a Python/DAZL process that connects
   to the ledger and executes various commands to manipulate the test
   contracts.
4. The test ledger may be stopped with `./stop-ledger.sh`.

The state of the local project directory may be totally reset by running
`./reset.sh`.
