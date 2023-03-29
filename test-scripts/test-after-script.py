#!/usr/bin/env python3
import os

with open('/home/user/install.log', 'a', encoding="utf-8") as the_file:
    the_file.write("AFTER SCRIPT: Hello from after script." + os.linesep)

with open('/mnt/srv/after-script.log', 'a', encoding="utf-8") as the_file:
    the_file.write("AFTER SCRIPT: Hello from after script." + os.linesep)
