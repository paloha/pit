#!/bin/bash

# pit.sh (Project Index in Terminal)
# This is a small command line utility which provides developers
# with a json database of projects they are currently working on
# and tools how to quickly navigate between the projects inside the
# terminal along with a simple management of virutual environments.

# Developed and tested on Ubuntu 20.04 and requires Python 3+
# Supports only virtual envs that contain `/bin/activate`

# Installation (if we even can call it that way)
# Copy this script to `~/.bash_scripts` or wherever you want to keep it
# Make it executable `chmod +x ~/.bash_scripts/pit.sh`
# Create an alias `pit` in `.bash_aliases` like so:
# `alias project="source ~/.bash_scripts/pit.sh"`
# Do `source ~/.bash_aliases` and now the `pit` command should
# be available in your terminal. In case you do not like `pit` or it
# conflicts with some other command name, use a different word, but also
# change the `PROGNAME` variable in the config bellow such that it matches.
# We are sourcing this script because otherwise the virualenv is not activated.

# Creates a default folder ~/.pit to store the db and default envs
# Does not alter developer's project files except creating a virtualenv if desired.
# No particular attention was paid to portability (i.e. do not try this on Win).
# Type `pit help` to see all the options. Type `pit` to start using it.

# Yes, it is a horrendeous mix of python and bash, but I started it as a small
# bash script and then I expanded it using Python, because bash = pain.
# Though, some things like activating an environment for current terminal,
# were much easier done from bash than from python.
# Also, I wanted this to be a single file.

# TODOs
# 1.
# Could be extened to handle online resources (such as google colab, overleaf).
# with `pit link URL` either by adding a link to the db.json, or creating
# a .urls file in the project itself. `pit links` would list them.
# Could be extended to handle colab projects. Just allow adding (name, URL) pair
# and when project is an URL do not run sub_env and instead of cd open browser.

## START OF THE PROGRAM #######################################################

function main {
# The whole thingy is wrapped in a main function to keep vars local
# Also it is not indented because the python code needs to not be indented to work.

# Small config, no need to edit anything here
local PROGNAME='pit';  # This can be changed if conflicts with other cmd utility
local DEFAULT=$(realpath ~/.pit);  # Default home folder of the program
local DB="$DEFAULT/db.json";  # Path to the database
local PYTHON=python3;  # Python interpreter to use (use python version 3 and above)
local FILEMANAGER=nautilus;  # Command which can open folders, if not desired ""
local CLEAR=clear;  # fresh screen after list or env subcommands. To turn off set to: ""
local INTERACTIVE=true;  # If true, program asks what to do next on list (faster to use)
# local GUIDED=

# Where are we?
local NAME=${PWD##*/};  # Name of the current folder

# How big is the terminal window?
$PYTHON -c "import os; exit(os.get_terminal_size()[0])";
local WIDTH=$?;

# Do we have all we need? (create if not)
mkdir -p $DEFAULT;
if [ ! -f $DB ]; then echo -n "{}">$DB; fi

# Accepting subcommands (thx https://gist.github.com/waylan/4080362)
sub_help(){
    echo "Usage: $PROGNAME <subcommand> [options]"
    echo "Subcommands:"
    echo "    help   Show this help message"
    echo "    init   Add cwd into projects and create .pit folder in the project"
    echo "    list   List all initialized projects"
    echo "    open   Open specified project based on its name or index"
    echo "    envs   List, activate, or create a virtual env"
    echo "    rm     Remove cwd, name, or idx from projects"
    echo ""
}

# Function for removing project paths from the database (no files harmed)
sub_rm(){
local PYTHON_DB_REMOVE=$(cat <<END
import json
with open('$DB', 'r') as obj:
    db = json.load(obj)
inv_db = {v: k for k, v in sorted(db.items())}
if '$1':
    try:  # Index
        idx = int('$1')
        name = path = None
        if idx == 0:
            print('ERROR: The (default) can not be removed.')
            exit(1)
        if idx < 0 or idx > len(db):
            print(f"ERROR: Can not remove. Index not in db.")
            exit(1)
        name = sorted(db)[idx - 1]
    except ValueError:  # Name
        name = '$1'
        idx = path = None
        if name == 'default':
            print('ERROR: The (default) can not be removed.')
            exit(1)
        if name not in db:
            print('ERROR: Can not remove. Name not in db.')
            exit(1)
else:
    idx = name = None
    path = '$PWD'
    if path == '$DEFAULT':
        print('ERROR: The (default) can not be removed.')
        exit(1)
    if path not in inv_db:
        print('ERROR: Can not remove. Not in db.')
        exit(1)
    name = inv_db[path]

db.pop(name)
with open('$DB', 'w') as obj:
    json.dump(db, obj, indent=4, sort_keys=True)
print(f'Successfully removed ({name}).')
exit(0)
END
)
    $PYTHON -c "$PYTHON_DB_REMOVE"
}

# Function for adding project path to database (Created .pit folder and updates db)
sub_init(){
local PYTHON_DB_INIT=$(cat <<END
# TODO add reinitialization feature (if .pit exists or PWD|NAME in db, sync PWD and NAME with db)
if '$1':
    print("ERROR: Subcommand 'init' does not accept any arguments.")
    exit(1)
import json, os
with open('$DB', 'r') as obj:
    db = json.load(obj)
inv_db = {v: k for k, v in sorted(db.items())}
if '$PWD' == '$DEFAULT':
    print('ERROR: The (default) is already in db.')
    exit(1)
elif '$PWD' in inv_db:
    name = inv_db['$PWD']
    if name != '$NAME':
        if '$NAME' in db:
            print("ERROR: Conflict of names in db. Remove '$NAME' from db before initializing this project.")
            exit(1)
        else:
            db['$NAME'] = '$PWD'
            del db[name]
    os.makedirs('.pit', exist_ok=True)
    print("Reinitialized under name: '$NAME'.")
    exit(0)
else:
    db['$NAME'] = '$PWD'
    os.makedirs('.pit', exist_ok=True)
    with open('$DB', 'w') as obj:
        json.dump(db, obj, indent=4, sort_keys=True)
    print(f"Project initialized under name: '$NAME'.")
    exit(0)
END
)
    $PYTHON -c "$PYTHON_DB_INIT";
    # sub_env;
}

# Function for showing the contents of the database
sub_list(){
is_pwd_in_db;
local INDB=$?;
local PYTHON_DB_LIST=$(cat <<END
if '$1':
    print("ERROR: Subcommand 'list' does not accept any arguments.")
    exit(1)
import json, os
with open('$DB', 'r') as obj:
    db = json.load(obj)
width = int('$WIDTH')
col1 = 5
col2 = len(max(db.keys(), key=len)) + 2 if len(db) != 0 else 9
col3 = width - col2 - col1 - 6
star = "*" if "$PWD" == "$DEFAULT" else ""
CCOL, CEND = ('\033[92m', '\033[0m') if star else ('', '')  # Font color
default_idx, default_name = f'{star}(0)', 'default'

if int("$INDB") == 0:
    proj = '[project] '
elif "$PWD" == "$DEFAULT":
    proj = '[default] '
else:
    proj = '[not initialized yet] '

# Header
print(proj + '\033[1;34m' + '$PWD' + '\033[0;0m')
print('\33[37m' + '▄' * width + '\033[0m')
print('\033[1;31;47m' + 'LIST OF PROJECTS' + ' ' * (width - 16) + '\033[0;0m')
print('\33[37m' + '▀' * width + '\033[0m')

# Content
print(f"{CCOL}{default_idx:<{col1}} {default_name:<{col2}} {'$DEFAULT'[-col3:]}{CEND}")
if len(db) > 0:
    print('─' * width)
for i, (name, path) in enumerate(sorted(db.items())):
    star = "*" if "$PWD" == path else ""
    CCOL, CEND = ('\033[92m', '\033[0m') if star else ('', '')  # Font color
    index = f'{star}({i+1})'
    dots = '...' if len(path) > col3 else ''
    print(f'{CCOL}{index:<{col1}} {name:<{col2}} {dots+path[-col3:]:<{col3}}{CEND}')
print('─' * width)
exit(0)
END
)
    $CLEAR;
    $PYTHON -c "$PYTHON_DB_LIST";
    if [ "$INTERACTIVE" = true ]; then
        read -r -p "Open[EXIT|idx|name]: " ans
        case "$ans" in
            "" | "exit" | "Exit") # Enter, N or n
                ;;
            *) # Anything else is considered an argument to open
                sub_open $ans
                ;;
        esac
    fi
}

# Finds available virtual environments and user can activate one or create new
sub_envs(){
    $CLEAR;
    local TMPFL=$DEFAULT/.tmp
    shopt -s dotglob  # Enables matching hidden folders
    shopt -s extglob  # Enables matching words stackoverflow.com/questions/3574463/
    # Finds folders (hidden or not) which contain bin/activate
    local DEFENVS=$(ls -d $DEFAULT/*/bin/activate 2>/dev/null);
    if [ $PWD != $DEFAULT ]; then
        local VENVS=$(ls -d */bin/activate 2>/dev/null);
    else
        local VENVS="";
    fi
    is_pwd_in_db;
    local INDB=$?;

local PYTHON_ENVS=$(cat <<END
import os
defaults = """$DEFENVS""".split()
found = """$VENVS""".split()
venvs = defaults + found
width = int('$WIDTH')

if int("$INDB") == 0:
    proj = '[project] '
elif "$PWD" == "$DEFAULT":
    proj = '[default] '
else:
    proj = ''

# Header
print(proj + '\033[1;34m' + '$PWD' + '\033[0;0m')
print('\033[37m' + '▄' * width + '\033[0m')
print('\033[1;31;47m' + 'LIST OF VIRTUAL ENVIRONMENTS' + ' ' * (width - 28) + '\033[0;0m')
print('\033[37m' + '▀' * width + '\033[0m')

# Content

# List default environments
if len(defaults) == 0:
    print('No default environments found.')
else:
    for i, venv in enumerate(defaults):
        ptv = venv[:-len('/bin/activate')]
        star = '*' if ptv == '$VIRTUAL_ENV' else ''
        CCOL, CEND = ('\033[92m', '\033[0m') if star else ('', '')  # Font color
        index = f'{star}({i}) '
        name = f"(default)/{venv[len('$DEFAULT')+1:-len('/bin/activate')]}"
        print(f'{CCOL}{index:<5}{name:<20} {venv:<{width-27}}{CEND}')
print('─' * width)

# List found environments
if len(found) == 0:
    print('No project environments found.')
else:
    for i, venv in enumerate(found):
        i = i+len(defaults)
        ptv = venv[:-len('/bin/activate')]
        star = '*' if os.path.join('$PWD', ptv) == '$VIRTUAL_ENV' else ''
        CCOL, CEND = ('\033[92m', '\033[0m') if star else ('', '')  # Font color
        index = f'{star}({i}) '
        print(f'{CCOL}{index:<5} {venv:<{width-6}}{CEND}')
print('─' * width)

ans = input('Exit[Enter] | Activate[idx] | Create[new_name]: ')

with open('$TMPFL', 'w+') as fl:
    if ans == '':
        exit(0)
    elif ans.startswith('-'):
        print('ERROR: Name can not start with "-".')
        exit(1)
    elif ans.isdigit():
        idx = int(ans)
        if idx >= len(venvs):
            print('ERROR: Bad index.')
            exit(1)
        print(venvs[int(ans)], file=fl)
        exit(10)
    else:
        if not os.path.exists(ans):
            print(ans, file=fl)
            exit(20)
        else:
            print('ERROR: Folder already exists.')
            exit(1)
END
)
    $PYTHON -c "$PYTHON_ENVS"
    local EC=$?
    local OUT=$(head -n 1 $TMPFL) && rm $TMPFL
    if [ $EC = 10 ]; then  # Activate
        echo 'Activating: ' $OUT
        source $OUT;
        has_jupyter;
    elif [ $EC = 20 ]; then
        echo "Creating new: " $OUT
        newvenv $OUT;
    fi
}

# Function for opening a desired project (cd into project and look for envs)
sub_open(){
local PYTHON_DB_OPEN=$(cat <<END
if not '$1':
    print("ERROR: Subcommand 'open' requires one argument. Idx or name.")
    exit(1)

import json
with open('$DB', 'r') as obj:
    db = json.load(obj)

idx, name = (int('$1'), None) if '$1'.isdigit() else (None, '$1')

# Return path based on provided index
if idx is not None:

    if idx > len(db):
        print(f"ERROR: Can not open. Index not in db."); exit(1)

    if idx == 0:
        print('$DEFAULT'); exit(0)

    name = sorted(db)[idx - 1]
    print(db[name]); exit(0)

else: # Return path based on provided name
    if name == 'default':
        print('$DEFAULT'); exit(0)

    if name not in db:
        print('ERROR: Can not open. Name not in db.'); exit(1)

    print(db[name]); exit(0)
END
)
    local OUT
    OUT=$($PYTHON -c "$PYTHON_DB_OPEN");
    local EC=$?

    if [ "$EC" = "0" ]; then
        cd $OUT;
        if [ "$FILEMANAGER" != "" ]; then
            $FILEMANAGER $OUT;
        fi
        echo 'Project opened successfully.';
        sub_envs;
    else
        echo $OUT;
    fi
}

# Function for checking if the current env has jupyter lab or jupyter
has_jupyter(){
    if [ "$INTERACTIVE" = true ]; then
        pip show jupyterlab >/dev/null 2>/dev/null;
        if [ $? = 0 ]; then
            read -r -p "Found Jupyter Lab, activate? [Y|n]: " ans
            case "$ans" in
                ""|[Yy]) # Blank, Y or y
                    jupyter-lab;
                    return 0;
                    ;;
                *) # Anything else is invalid
                    ;;
            esac
        fi
        pip show jupyter >/dev/null 2>/dev/null;
        if [ $? = 0 ]; then
            read -r -p "Found Jupyter, activate? [Y|n]: " ans
            case "$ans" in
                ""|[Yy]) # Blank, Y or y
                    jupyter notebook;
                    return 0;
                    ;;
                *) # Anything else is invalid
                    ;;
            esac
        fi
    fi
}

# Checks if PWD is a stored project
is_pwd_in_db(){
local PYTHON_PWDINDB=$(cat <<END
import json
with open('$DB', 'r') as obj:
    db = json.load(obj)
inv_db = {v: k for k, v in sorted(db.items())}
if '$PWD' in inv_db:
    exit(0)
else:
    exit(1)
END
)
    $PYTHON -c "$PYTHON_PWDINDB"
    local EC=$?
    return $EC
}

# Handle the subcommands and call appropriate functions
local SUBCOMMAND=$1
case $SUBCOMMAND in
    "")
        is_pwd_in_db;
        if [ $? = 0 ]; then
            sub_envs;
        elif [ $PWD = $DEFAULT ]; then
            sub_envs;
        else
            echo ""
            echo "This folder is not yet initialized as a project.";
            sub_list;
        fi
        ;;
    "-h" | "--help")
        sub_help
        ;;
    *)
        shift
        sub_${SUBCOMMAND} $@
        if [ $? = 127 ]; then
            echo "Error: '$SUBCOMMAND' is not a known subcommand." >&2
            echo "Run '$PROGNAME --help' for a list of known subcommands." >&2
            return
        fi
        ;;
esac
}

# Creates a new environment and activates it
function newvenv {  # Takes name as parameter
    virtualenv $1;
    source $1/bin/activate;
    echo "Virtual environment active.";
}

main $1 $2;

## END OF THE PROGRAM #########################################################

# TAILGIT
# Yes, instead of using git, I really put the old code to the back of the file.
# I call it Tailgit and if you do not like it... well, that is not my problem.

# This was the first code which just listed the environments and activated one.
# shopt -s extglob  # Enables matching words stackoverflow.com/questions/3574463/
# # Finds folders (hidden or not) which contain bin/activate
# VENVS=$(ls -d */bin/activate 2>/dev/null);
# N=$(echo $VENVS | wc -w);  # Number of matches
#
# # Takes name as parameter
# function newvenv {
#     virtualenv $1;
#     source $1/bin/activate;
#     echo "Virtual environment active.";
# }
#
# if [ "$N" = "0" ]; then
#     while true; do
#         read -r -p "No virtualenv found. Create new? [Y|n|name]: " ans
#         case "$ans" in
#             ""|[Yy]) # Blank, Y or y
#                 newvenv ".venv";
#                 break;;
#             [Nn]) # N or n
#                 echo "OK good bye.";
#                 break;;
#             ?(.)+([-a-zA-Z0-9_]))
#                 newvenv $ans;
#                 break;;
#             *) # Anything else is invalid
#                 echo "Invalid choice, please type y or n or name of the env.";
#                 ;;
#         esac
#     done
# else
#     while true; do
#         echo "Found the following virtual environments:";
#         for (( i=1; i<=${N}; i++ )); do
#             echo "  ($i) $(echo $VENVS | awk -v i=$i '{print $i}')";
#         done
#         # Ask user
#         read -r -p "Quit [Enter] | Activate [int] | Create new [name]: " ans
#         case "$ans" in
#             "" | [Qq])
#                 echo "OK good bye.";
#                 break;;
#             +([0-9])) # Single digit number [1-$N])
#                 if [ "$ans" = "0" ]; then
#                     echo "Indexing starts at 1.";
#                 elif (( $ans > $N )); then
#                     echo "Too high number.";
#                 else
#                     echo "Activating...";
#                     source $(echo $VENVS | awk -v ans=$ans '{print $ans}');
#                 fi
#                 break;;
#             ?(.)+([-a-zA-Z0-9_]))
#                 newvenv $ans;
#                 break;;
#             *) # Anything else is invalid
#                 echo "Invalid choice.";
#                 ;;
#         esac
#     done
# fi
