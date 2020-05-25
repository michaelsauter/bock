# Bock mocks binaries.

CAUTION: `bock` is just a proof-of-concept at this stage. It is by no means feature complete or even correct in many cases. Use at your own risk.

Sometimes, one might mock a binary instead of using the real one.
An example use case is mocking `oc`, the CLI binary to interact with OpenShift.
OpenShift is, depending on the host, tricky to install and resource intensive.
Using `bock`, one can mock the interaction to avoid running an actual cluster.

`bock` works by storing the mocked interactions in a temporary file named
`.bock-want` and the actual invocations in a file named `.bock-got`, which can
be compared by calling `mock --verify`.

## Usage

To use `bock`, download `bock.sh` into a folder, but give it the  name of the
binary to mock, e.g. `git` or `oc`. Then prepend your `$PATH` with that folder
in your test script. As an example, see
https://github.com/michaelsauter/bock/blob/master/tests/run.sh or the following
example:

```
#!/usr/bin/env bash
set -ue

# Download script
curl -L "https://raw.githubusercontent.com/michaelsauter/bock/master/bock.sh" -o oc && chmod +x oc

# Prepend to your path
PATH=.:$PATH

# Init / clean state
oc mock --init

# Define interactions
oc mock --receive whoami --stdout "Max Mustermann" --times 1

# Run code that uses "oc" binary ... typically you'd execute your script to test here
oc whoami

# Check interactions
oc mock --verify
```
