#!/bin/bash

# This bash script and this function are just a necessary evil because
# without bash, we can not change the active terminal (cd somewhere or
# activate a venv). And without this function, we can not make the
# variables local, which would clutter environment variables upon sourcing.

# Therefore, we just pass all the arguments to the python script which then
# does all the work and in case we want to alter the state of the terminal,
# we take the output of the python script and do what's needed in bash.

# We are using a tmp file for passing information from python to bash
# because there is no other elegant way except using stdout.

function main {
    local python=python3;
    local script_dir=$(dirname "$(readlink -f "${BASH_SOURCE[0]}")");
    local bash_script=$script_dir/pit.sh;
    local python_script=$script_dir/pit.py;
    local default_dir=$(readlink -f ~/.pit);
    local tmp_file=$default_dir/pit.tmp;
    local continue=true;
    while $continue
    do
        continue=false;  # By default we run the python_script only once
        $python $python_script "$@";  # Passing on all the arguments
        if [ -f $tmp_file ]; then  # If python sends back some command
            local command=$(head -n 1 $tmp_file) && rm $tmp_file;  # Read it
            eval $command;  # Execute it
            # In case the command contains 'continue=true' we do another loop
        fi
    done
}
main "$@"

# clone repo, place the folder somewhere where you want to keep it
# e.g. /usr/local/bin or ~/bin or ~/.local/bin or /opt/ or ~/.bash_scripts
# make pit.sh executable or create a link to pit.sh somewhere else which is
# executable and make an alias to it with source.
