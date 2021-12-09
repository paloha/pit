import os
import json
import argparse
from pathlib import Path
from functools import partial
from argparse import RawTextHelpFormatter

HEADLINE = '''
─────────────────────────────────────────────────────
  █▀█ █ ▀█▀  │  Welcome to Project Index in Terminal!
  █▀▀ █  █   │  Organize your projects with ease.
─────────────────────────────────────────────────────
'''

# List of files or folders which might indicate the parent folder is a project
SNITCHES = ['.pit', '.git', '.idea']


def get_help_msg(prefix, func, start=0, n=1, end=None):
    """
    Get n lines of help message defined start lines after prefix or until end.
    """
    def find_i(prefix):
        return [lines.index(line) for line in lines if line.startswith(prefix)]

    lines = list(map(str.strip, func.__doc__.split("\n")))
    i = find_i(prefix)
    if len(i) >= 1:
        i = i[0]  # We take first occurence of prefix
        j = i + start + n if end is None else find_i(end)[0]
        if start == 0:
            lines[i] = lines[i][len(prefix):]
        return ' '.join(lines[i + start:j])
    return None


def subcommand(arguments=[], parent=None, cmd=None, als=None):
    """
    Decorator for functions to register them as subcommands.
    """
    def decorator(func):
        command = cmd or func.__name__
        aliases = als or []
        p = parent.add_parser(
            command, aliases=aliases, help=get_help_msg('H : ', func),
            description=get_help_msg('', func, end='H : '))
        for arg in arguments:
            if 'help' not in arg[1]:
                arg_name = arg[0][0].replace('-', '')
                arg[1]['help'] = get_help_msg(f'{arg_name} : ', func, 1)
            p.add_argument(*arg[0], **arg[1])
        p.set_defaults(func=func)
    return decorator


def arg(*args, **kwargs):
    """
    Takes all arguments and separates them into args list and kwargs dict.
    """
    return ([*args], kwargs)


# def _get_db(path, mode='r'):
#     """
#     Opens a json file on path in mode.
#     Creates it if does not exist.
    # """


def _get_conda_envs():
    pass


def _get_venvs(path):
    pass


def _get_venv_type(path):
    pass


def _print_header(title):
    pass


def _get_groups():
    return ['env', 'url']


def _valid_id(val, kind=None):
    # set kind with partial to either project or resource
    # check if val is an int in correct range
    # or if it is a name which is in the database
    # raises ArgumentTypeError, TypeError, or ValueError
    return val


def _unused_name(val, kind=None):
    # set kind with partial to either project or resource
    # check if val is not already a used name in the db
    # raises ArgumentTypeError, TypeError, or ValueError
    return val


def _send2bash(command, file=None):
    """Uses a file to communicate with bash."""
    with open(file, 'w+') as fl:
        print(command, file=fl)


if __name__ == '__main__':

    # Default CONFIG (read config from a file and rewrite default )
    WIDTH = os.get_terminal_size()
    HOME =   # Forbidden folder (can not init a project)

    # The following entries must be also changed in pit.sh if changed
    DEFAULT_DIR = os.path.join(os.path.expanduser('~'), '.pit')
    TMP_FILE = os.path.join(DEFAULT_DIR, 'pit.tmp')
    FORBIDDEN = os.path.dirname(DEFAULT_DIR)



    s2b = partial(_send2bash, file=TMP_FILE)

    # create the top-level parser
    parser = argparse.ArgumentParser(
        prog='pit', description=HEADLINE, formatter_class=RawTextHelpFormatter)

    # Handling interactivity [optional arguments]
    group = parser.add_mutually_exclusive_group()
    group.add_argument('-i', '--interactive', action='store_true')
    group.add_argument('-n', '--noninteractive', action='store_true')

    # subcommands are handles by using a decorator([arguments])
    pit_sub = parser.add_subparsers(help="SUB-COMMAND HELP:")

    # Register func as a subcommand of pit (decorator)
    pit_subcommand = partial(subcommand, parent=pit_sub)

    @pit_subcommand(
        [arg('path', default=os.getcwd(), type=Path, nargs='?')])
    def init(args):
        """
        Adds path into projects and creates .pit folder inside the project.

        H : initialize a project

        Parameters
        ----------
        path : str, default=os.getcwd()
            path to project which should be (re)initialized (default=CWD)
        """
        print(f'Init for {args.path}')

    @pit_subcommand(
        [arg('path', default=os.getcwd(), type=Path, nargs='?')])
    def find(args):
        """
        Crawls subdirectories of the specified path and looks for
        'snitches' which may give away the information that the
        parent dir is a project. E.g. .pit, .git, .idea, etc.

        H : find projects on path and enumerate them

        Parameters
        ----------
        path : str, default=os.getcwd()
            path to directory where to look for projects recursively
        """
        print('Func find.')

    @pit_subcommand(
        [arg('-a', '--all', action='store_true')])
    def index(args):
        """
        Lists active projects and their ids.

        H : list active projects

        Parameters
        ----------
        a : (all) bool, default=False
            list all (also inactive) projects
        """
        print('List of projects')

    @pit_subcommand([
        arg('pid', nargs=1, type=partial(_valid_id, kind='project')),
        arg('-n', '--name', nargs=1, type=str),
        arg('-p', '--path', nargs=1, type=Path),
        arg('-s', '--status', action='store_true')])
    def update(args):
        """
        H : update the project's database entry

        Parameters
        ----------
        pid : int>0 or str
            index or name of the project
        n : str
            new name
        p : str
            new path
        s : bool
            toggle status
        """

    @pit_subcommand([arg('pid', type=partial(_valid_id, kind='project'))])
    def goto(args):
        """
        Change the CWD to project DIR.

        H : change CWD to project DIR based on its name or index

        Parameters
        ----------
        pid : int>0 or str
            index or name of the project
        """

    @pit_subcommand([arg('pid', type=partial(_valid_id, kind='project'))])
    def drop(args):
        """
        H : drops a project from the database

        Parameters
        ----------
        pid : str
            name or index of the project which should be dropped
        """
        print('Func drop')

    @pit_subcommand()
    def start(args):
        """
        H : executes the start script if exists
        """
        print('Func start')

    @pit_subcommand()
    def stop(args):
        """
        H : executes the stop script if exists
        """
        print('Func stop')

    @pit_subcommand([
        arg('-g', '--group', choices=_get_groups()),
        arg('-n', '--name', nargs=1, type=partial(_unused_name, kind='pit')),
        arg('-d', '--description', nargs=1),
        arg('-l', '--location', nargs=1)])
    def add(args):
        """
        H : add a pit resource to the project

        Parameters
        ----------
        g : (group) : str
            one of the configured groups
        n : (name) : str
            unique name of the pit resource
        d : (description) : str
            description of the pit resource
        l : (location) : str
            location (e.g. URL, path, email) which can be opened
        """
        if not any([args.group, args.name, args.description, args.location]):
            raise argparse.ArgumentError('At least one argument is required.')
        print('Function add.')

    @pit_subcommand(
        [arg('group', default=None, choices=_get_groups(), nargs='*')],
        cmd='list')  # als=['ls']
    def list_pits(args):
        """
        H : list project's pits

        Parameters
        ----------
        group : str
            list of groups to include in the list (default all)
        """
        print('Function list.')

    @pit_subcommand([arg('id', type=partial(_valid_id, kind='pit'))])
    def open(args):
        """
        H : open specified pit based on it's group

        Parameters
        ----------
        id : int > 0
            index of the pit which should be opened
        """
        print('Function open.')

    @pit_subcommand([
        arg('id', type=partial(_valid_id, kind='project')),
        arg('-g', '--group', choices=_get_groups()),
        arg('-n', '--name', nargs=1, type=partial(_unused_name, kind='pit')),
        arg('-d', '--description', nargs=1),
        arg('-l', '--location', nargs=1)])
    def edit(args):
        """
        H : edit pit's group, name, description or location

        Parameters
        ----------
        id : int > 0
            index of the pit which should be edited
        g : (group) : str
            one of the configured groups
        n : (name) : str
            unique name of the pit resource
        d : (description) : str
            description of the pit resource
        l : (location) : str
            location (e.g. URL, path, email) which can be opened
        """
        print('Function edit.')

    @pit_subcommand([arg('id', type=partial(_valid_id, kind='project'))])
    def delete(args):
        """
        H : delete a pit resource from the project

        Parameters
        ----------
        id : int > 0
            index of the pit which should be deleted
        """
        print('Function delete.')

    args = parser.parse_args()

    print('RUNNING PIT')
    print(f'CWD: {os.getcwd()}')
    print(f'DEF: {DEFAULT_DIR}')
    print(f'TMP: {TMP_FILE}')
    print()

    print('ARGS: ', args)
    if 'func' in args:
        args.func(args)




    # with open(TMP_FILE, 'w+') as fl:
    #     if os.getcwd() == os.path.join(DEFAULT_DIR, '.pit'):
    #         print('cd .. && continue=true', file=fl)
    #     elif os.getcwd() == DEFAULT_DIR:
    #         print('source .venv/bin/activate', file=fl)
