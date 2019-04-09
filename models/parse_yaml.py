import yaml
from tools.action_parser import (ActionParser)
with open("client_record_states.yml", "r") as file_descriptor:
    yml=yaml.load(file_descriptor)

state_nodes = [state['actions'] for state in yml['states'] if 'actions' in state]

for i in state_nodes:
    for assignments in i:
        print(assignments)
        parser = ActionParser()
        result = parser.parse(assignments)
        print(result)
        print(assignments)









