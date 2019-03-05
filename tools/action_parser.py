from pyparsing import StringEnd, Word, alphas


class Action:
    pass


class ActionParser:
    def __init__(self) -> None:
        action = Word(alphas)
        action.setParseAction(Action)

        self.grammar = action + StringEnd()

    def parse(self, string: str) -> Action:
        return self.grammar.parseString(string)
