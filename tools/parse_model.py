#!/usr/bin/env python

import argparse
import sys
from typing import List

import yaml
from pyparsing import ParseException, ParseSyntaxException

from tools.action_parser import ActionParser


def main(argv: List[str]) -> int:
    argparser = argparse.ArgumentParser()
    argparser.add_argument('file', metavar='FILE', help='YAML Model')
    args = argparser.parse_args(argv[1:])

    with open(args.file, 'r') as input_file:
        yml = yaml.load(input_file)
        for state in yml['states']:
            if 'actions' not in state:
                continue
            for action in state['actions']:
                try:
                    ActionParser().parse(action)
                except (ParseException, ParseSyntaxException) as e:
                    print(ParseException.explain(e))
                    return 1

    return 0


if __name__ == '__main__':
    sys.exit(main(sys.argv))
