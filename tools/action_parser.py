from typing import Dict, List

from pyparsing import (Forward, Keyword, Literal, Optional, ParseResults, StringEnd, Suppress, Word,
                       WordEnd, WordStart, ZeroOrMore, alphanums, alphas, dblQuotedString,
                       delimitedList, sglQuotedString)

from rflx.expression import FALSE, TRUE, Attribute, Call, Expr, Value
from rflx.parser import Parser


class Action:
    def __repr__(self) -> str:
        args = '\n\t' + ',\n\t'.join(f'{k}={v!r}' for k, v in self.__dict__.items())
        return f'{self.__class__.__name__}({args})'.replace('\t', '\t    ')

    def __eq__(self, other: object) -> bool:
        if isinstance(other, self.__class__):
            return self.__dict__ == other.__dict__
        return NotImplemented


class Assignment(Action):
    def __init__(self, left: str, right: Expr) -> None:
        self.left = left
        self.right = right


class String(Expr):
    def __init__(self, name: str) -> None:
        self.name = name

    def __neg__(self) -> Expr:
        raise NotImplementedError

    def simplified(self, facts: Dict[Attribute, Expr] = None) -> Expr:
        raise NotImplementedError


class BooleanLiteral(Expr):
    def __init__(self, value: str) -> None:
        self.value = value

    def __neg__(self) -> Expr:
        raise NotImplementedError

    def simplified(self, facts: Dict[Attribute, Expr] = None) -> Expr:
        raise NotImplementedError


class Variable(Value):
    def __init__(self, name: str, components: List[str] = None) -> None:
        super().__init__(name)
        self.components = components or []

    def __str__(self) -> str:
        components = '.'.join(self.components)
        if components:
            components = f'.{components}'
        if self.negative:
            return f'(-{self.name}{components})'
        return f'{self.name}{components}'


class Read(Attribute):
    def __init__(self, name: str, channel: str) -> None:
        super().__init__(name)
        self.channel = channel


class Write(Attribute, Action):
    def __init__(self, name: str, channel: str, item: Expr) -> None:
        super().__init__(name)
        self.channel = channel
        self.item = item


LP = Suppress(Literal('(')).setName('"("')
RP = Suppress(Literal(')')).setName('")"')


class ActionParser:
    def __init__(self) -> None:
        identifier = WordStart(alphas) + Word(alphanums + '_') + WordEnd(alphanums + '_')
        identifier.setName('Identifier')

        boolean_literal = Keyword('True') | Keyword('False')
        boolean_literal.setParseAction(parse_boolean_literal).setName('BooleanLiteral')

        string = sglQuotedString | dblQuotedString
        string.setParseAction(parse_string).setName('String')

        variable = identifier + ZeroOrMore(Suppress(Literal('.')) - identifier)
        variable.setParseAction(parse_variable).setName('Variable')

        read = (identifier + Suppress(Literal('\''))
                + Suppress(Literal('Read')) - LP - identifier - RP)
        read.setParseAction(parse_read).setName('ReadAttribute')

        call = Forward()
        argument = read | call | Parser.numeric_literal() | variable | string
        call <<= identifier + LP - Optional(delimitedList(argument)) - RP
        call.setParseAction(parse_call).setName('Call')

        write = (identifier + Suppress(Literal('\'')) + Suppress(Literal('Write'))
                 - LP - identifier - Suppress(Literal(',')) - (call | variable) - RP)
        write.setParseAction(parse_write).setName('WriteAttribute')

        assignment = (identifier + Keyword(':=')
                      - (read | boolean_literal | string | call | (variable + StringEnd())
                         | Parser.mathematical_expression()))
        assignment.setParseAction(parse_assignment).setName('Assignment')

        action = write | assignment

        self.grammar = action + StringEnd()

    def parse(self, string: str) -> Action:
        return self.grammar.parseString(string)[0]


def parse_assignment(tokens: ParseResults) -> Assignment:
    return Assignment(tokens[0], tokens[2])


def parse_literal(tokens: ParseResults) -> Value:
    return Value(tokens[0])


def parse_boolean_literal(tokens: ParseResults) -> BooleanLiteral:
    if tokens[0] == 'True':
        return TRUE
    if tokens[0] == 'False':
        return FALSE
    assert False
    return None


def parse_string(tokens: ParseResults) -> String:
    return String(tokens[0][1:-1])


def parse_call(tokens: ParseResults) -> Call:
    return Call(tokens[0], tokens[1:])


def parse_variable(tokens: ParseResults) -> Variable:
    return Variable(tokens[0], tokens[1:])


def parse_read(tokens: ParseResults) -> Read:
    return Read(tokens[0], tokens[1])


def parse_write(tokens: ParseResults) -> Write:
    return Write(tokens[0], tokens[1], tokens[2])
