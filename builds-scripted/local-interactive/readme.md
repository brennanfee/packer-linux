# Local Interactive Script Testing

## Overview

This directory is used for testing the interactive script. Given that script requires human
intervention there are no automated tests for that script.

## Running Tests

There are two ways to test the interactive script. The first is inside a VM, this is helpful to test
the option at the end where you want to immediately install with the provided options. The second is
outside a VM on the local machine. This second option is best when you want to test the generation
of a config file given the provided options.

To run a VM build use the build.bash script provided in the directory. To run a local build use the
run.bash script provided in the directory. For both scripts you can see their respective help
information for usage.
