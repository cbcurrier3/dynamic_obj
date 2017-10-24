# dynamic_obj
Version 9
UPDATED 10/10/2017

------------------------------
INSTALL
------------------------------

cp dynam_obj_upd.sh $CPDIR/bin
chmod 755 $CPDIR/bin/dynam_obj_upd.sh


------------------------------
RUN
------------------------------
This script is intended to run on a Check Point Firewall

Usage:
  dyn_obj_upd.sh <options>

Options:
  -o                    Dynamic Object Name (required)
  -u                    url to retrieve IP Address list (optional)
  -f                    local file name of IP Address list (optional)
  -a                    action to perform (required) includes:
                              run (once), on (schedule), off (from schedule), stat (status)
  -h                    show help

------------------------------
EXAMPLES
------------------------------
IMPORTANT:  Be sure that the dynamic object you are working with has been created
	    in your security policy and pushed out to the gateway. If not you will
	    be updating an object that will have no effect.

Activate an object
  dynam_obj_upd.sh -o myDynObj -f /home/admin/myIPlist.txt -a on

Activate a web based list
  dynam_obj_upd.sh -o myDynObj -u https://mywebserver.com/myIPlist.txt -a on

Run Right away
     dynam_obj_upd.sh -o myDynObj -u https://mywebserver.com/myIPlist.txt -a run

Deactivate an object
    dynam_obj_upd.sh -o myDynObj -a off

Get Object status
       dynam_obj_upd.sh -o myDynObj -a stat

------------------------------
LOGS
------------------------------

A Log of events can be found at $FWDIR/log/dynam_obj_upd.log. 

------------------------------
Change Log
------------------------------

V9 - 10/10/17 - updated file names, corrected Object Naming to apply only to "Scheduled Tasks", added details to README on Object Usage
V8 - 10/6/17  - Added prefix to object Name "DYOBJ_"
v7 - 10/4/17  - Bug Fixes - Corrected Local file check error 
v6 - 10/4/17  - Bug corrections and updated Log status posts including integrating timeout variable into cpd schedule command.
v5 - 10/4/17  - Added url checking and proxy if configured integration
v4 - 10/4/17  - Added logging to $FWDIR/log/dyn_obj_upd.log


------------------------------
Authors
------------------------------
Nuno Sousa - nsousa@checkpoint.com
CB Currier - ccurrier@checkpoint.com

