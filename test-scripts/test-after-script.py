#!/usr/bin/env python3
import os

with open('/home/usr/install.log', 'a') as the_file:
    the_file.write(f"AFTER SCRIPT: Hello from after script." + os.linesep)
