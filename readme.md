![alt text](https://repository-images.githubusercontent.com/431926729/f90934d5-9f08-441c-8018-ee86999ad8b9)

# pit.sh (Project Index in Terminal)

PIT is a small CRUD command line utility that provides developers with a
json database of projects they are currently working on and tools to use it.

Its main features are:

* quick overview and navigation between projects
* simple management of virtual environments
* automatic activation of development tools like Jupyer
----

## Platform

Developed and tested on Ubuntu 20.04. Requires bash and Python3.
So far supports only virtual envs which contain `/bin/activate`.
No particular attention was paid to portability yet (i.e. do not try this on Win).

## Installation (if we can even call it that way)

1. Copy `pit.sh` script to `~/.bash_scripts` or wherever you keep your scripts
1. Make it executable with `chmod +x ~/.bash_scripts/pit.sh`
1. Create an alias `pit` in `.bash_aliases` like so:
`alias project="source ~/.bash_scripts/pit.sh"`
1. Do `source ~/.bash_aliases` and now the `pit` command should
be available in your terminal

(This script needs to be sourced, otherwise, the activation of virualenv would not work.)

**All your files are safe**

PIT creates and uses a default folder `~/.pit` to store the db and default envs.
It does not alter project files in any way nor can it remove them.
Inside the project, it only creates a `.pit` folder for keeping project-specific
data and virtualenv folder if desired.

## Usage

Type `pit help` to see all the options. Type `pit` to start using it.
```
Subcommands:
    help   Show this help message
    init   Add cwd into projects and create .pit folder in the project
    list   List all initialized projects
    open   Open specified project based on its name or index
    envs   List, activate, or create a virtual env
    rm     Remove cwd, name, or idx from projects
```

## Configuration

In case you do not like the name `pit` or it conflicts with some other command,
use a different alias, but also change the `PROGNAME` variable in the script
config such that it matches the alias.

It is also easy to configure the default PIT folder, which python interpreter
is used, path to the json database, used filemanager, etc.

## Uninstallation

To uninstall, just remove the `pit.sh` file, remove the alias, remove `~/.pit`
and if you do not want to keep any data stored with pit per project, also remove
`.pit` folder from each project.

## Note
Yes, it is a horrendous mix of python and bash, but I started it as a small
bash script and then I expanded it using Python, because bash = pain.
Though, some things like activating an environment for the current terminal
were much easier done from bash than from python. Also, I wanted this to be a
single file.

## Future of the project
My current self is in hope of extending the functionality and rewriting the whole
project pure in Python. Maybe even in ncurses if I feel adventurous...
So in case, you would like to use such a tool, please star the repo or let me know.
It helps with motivation.

I planned to extend the functionality to support per-project start and stop scripts,
and per-project config, plus support for additional lists of resources, such as URLs, etc.
But do not be fooled, the project might just get stalled, as I will be the only
one in the world to use it. Who knows.

## License

Free for personal use. I am too lazy to google the exact license right now.
