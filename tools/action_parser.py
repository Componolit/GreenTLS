import typing as tp

from pyparsing import (Forward, Keyword, Literal, Optional, ParseResults, Suppress, Word, alphanums,
                       alphas, dblQuotedString, delimitedList, sglQuotedString)
from rflx.expression import Number
from rflx.parser import Parser


class Action:
    def __repr__(self) -> str:
        args = '\n\t' + ',\n\t'.join(f"{k}={v!r}" for k, v in self.__dict__.items())
        return f'{self.__class__.__name__}({args})'.replace('\t', '\t    ')

    def __eq__(self, other: object) -> bool:
        if isinstance(other, self.__class__):
            return self.__dict__ == other.__dict__
        return NotImplemented


class Identifier(Action):
    def __init__(self, name: str) -> None:
        self.name = name


class Assignment(Action):
    def __init__(self, left: Identifier, right: Action) -> None:
        self.left = left
        self.right = right


class String(Action):
    def __init__(self, name: str) -> None:
        self.name = name


class Variable(Action):
    def __init__(self, name: str) -> None:
        self.name = name


class Literaldef(Action):
    def __init__(self, name: str) -> None:
        self.name = name


class BooleanLiteral(Literaldef):
    pass


class Function(Action):
    def __init__(self, name: str, args: tp.List[tp.Union[Number, Action]]) -> None:
        self.name = name
        self.args = args


class ActionParser:
    def __init__(self) -> None:
        identifier = Word(alphanums + "_")
        identifier.setParseAction(parse_identifier)
        literal = Word(alphanums + "_")
        literal.setParseAction(parse_literal)

        boolean_literal = Keyword("True") | Keyword("False")
        boolean_literal.setParseAction(parse_literal)

        string = sglQuotedString | dblQuotedString
        string.setParseAction(parse_string)

        lpr = Suppress(Literal("("))
        rpr = Suppress(Literal(")"))
        functor_name = Word(alphanums + "_")

        variable = Word(alphas + "_", exact=1) + Optional(Word(alphanums + "_"))
        variable.setParseAction(parse_variable)

        multi_arg_func: Forward = Forward()
        arg = multi_arg_func | Parser.numeric_literal() | variable | string
        args = delimitedList(arg)
        multi_arg_func <<= functor_name + lpr + Optional(args) + rpr

        multi_arg_func.setParseAction(parse_func)

        assignment = (identifier + Keyword(":=")
                      + (boolean_literal | string | Parser.numeric_literal()
                         | multi_arg_func | literal))
        assignment.setParseAction(parse_assignment)

        self.grammar = assignment

    def parse(self, string: str) -> Action:
        return self.grammar.parseString(string)[0]


def parse_assignment(tokens: ParseResults) -> Assignment:
    return Assignment(tokens[0], tokens[2])


def parse_identifier(tokens: ParseResults) -> Identifier:
    return Identifier(tokens[0])


def parse_literal(tokens: ParseResults) -> Literaldef:
    return Literaldef(tokens[0])


def parse_string(tokens: ParseResults) -> String:
    return String(tokens[0][1:-1])


def parse_func(tokens: ParseResults) -> Function:
    return Function(tokens[0], tokens[1:])


def parse_variable(tokens: ParseResults) -> Variable:
    tokens[0] = "".join(tokens)
    return Variable(tokens[0])
