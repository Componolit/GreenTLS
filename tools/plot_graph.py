#!/usr/bin/env python3
# pylint: disable=missing-docstring

import argparse
import logging
import sys

from pathlib import Path
from typing import Dict, List, Set

import pygraphviz as pgv  # type: ignore
import yaml


def main() -> None:
    argparser = argparse.ArgumentParser()
    argparser.add_argument('file', metavar='FILE', help='YAML State Chart')
    argparser.add_argument('-v', '--verbose', help='output extra information', action='store_true')
    args = argparser.parse_args()

    logging_level = logging.WARNING
    if args.verbose:
        logging_level = logging.INFO
    logging.basicConfig(format='%(levelname)s: %(message)s', level=logging_level)

    with open(args.file, 'r') as input_file:
        yml = yaml.load(input_file)

    if 'initial' not in yml:
        logging.critical('Missing \'initial\'')
        sys.exit(1)

    if 'final' not in yml:
        logging.critical('Missing \'final\'')
        sys.exit(1)

    if 'states' not in yml:
        logging.critical('Missing \'states\'')
        sys.exit(1)

    graph = pgv.AGraph(directed=True, splines='ortho')

    initial_node = 'INITIAL_' + yml['initial']
    graph.add_node(initial_node, color='black', shape='point')
    graph.add_edge(initial_node, yml['initial'], color='black')

    state_nodes = [state['name'] for state in yml['states']]
    graph.add_nodes_from(state_nodes, color='black')
    graph.add_node(yml['final'], fontname='bold')

    data_nodes: Set[str] = set()

    for state in yml['states']:
        if state['name'] != yml['final']:
            if 'transitions' in state:
                add_transitions(graph, state['name'], state['transitions'])
            else:
                logging.error('No transitions from \'%s\'', state['name'])
        elif 'transitions' in state:
            logging.error('Final node \'%s\' should have no outgoing transitions', state['name'])

        if 'channels' in state:
            add_channels(graph, state['name'], state['channels'])
        else:
            logging.info('No \'channels\' in \'%s\'', state['name'])

        if 'data' in state:
            data_nodes.update({data['name'] for data in state['data']})
            add_data(graph, state['name'], state['data'])
        else:
            logging.info('No \'data\' in \'%s\'', state['name'])

    verify_graph(graph, state_nodes, data_nodes)

    basename = Path(args.file).name.rsplit('.')[0]
    graph.write(basename + '.dot')
    graph.layout('dot')
    graph.draw(basename + '.png')


def add_transitions(graph: pgv.AGraph, state_name: str, transitions: List[Dict[str, str]]) -> None:
    for transition in transitions:
        if transition['target'] not in graph.nodes():
            logging.error('Transition to unknown state \'%s\'', transition['target'])
        condition = transition['condition'] if 'condition' in transition else ''
        graph.add_edge(state_name, transition['target'], xlabel=condition, color='black')


def add_channels(graph: pgv.AGraph, state_name: str, channels: List[Dict[str, str]]) -> None:
    for channel in channels:
        graph.add_node(channel['name'], color='blue', shape='box')
        if channel['access'].startswith('r'):
            graph.add_edge(channel['name'], state_name, color='blue')
        if channel['access'].endswith('w'):
            graph.add_edge(state_name, channel['name'], color='magenta')


def add_data(graph: pgv.AGraph, state_name: str, data_list: List[Dict[str, str]]) -> None:
    for data in data_list:
        graph.add_node(data['name'], color='green', shape='box')
        if data['access'].startswith('r'):
            graph.add_edge(data['name'], state_name, color='green')
        if data['access'].endswith('w'):
            graph.add_edge(state_name, data['name'], color='orange')


def verify_graph(graph: pgv.AGraph, state_nodes: List[str], data_nodes: Set[str]) -> None:
    for node in state_nodes:
        if not [edge for edge in graph.edges(node) if edge[1] == node]:
            logging.error('No transition to \'%s\'', node)
    for node in data_nodes:
        if not [edge for edge in graph.edges(node) if edge[0] == node]:
            logging.error('No read from \'%s\'', node)
        if not [edge for edge in graph.edges(node) if edge[1] == node]:
            logging.error('No write to \'%s\'', node)


if __name__ == '__main__':
    main()
