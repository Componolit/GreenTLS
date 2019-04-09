import typing as tp

from pyparsing import (Forward, Keyword, Literal, Optional, ParseResults, Suppress, Word, alphanums,
                       alphas, dblQuotedString, delimitedList, sglQuotedString)
from rflx.expression import Attribute, Expr, LogExpr, MathExpr, Value
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
    def __init__(self, left: Identifier, right: Expr) -> None:
        self.left = left
        self.right = right


class String(Expr):
    def __init__(self, name: str) -> None:
        self.name = name


class BooleanLiteral(LogExpr):
    def __init__(self, value: str) -> None:
        self.value = value

    def simplified(self, facts: tp.Dict['Attribute', 'MathExpr'] = None) -> LogExpr:
        raise NotImplementedError

    def symbol(self) -> str:
        raise NotImplementedError


class Function(MathExpr):
    def __init__(self, name: str, args: tp.List[Expr]) -> None:
        self.name = name
        self.args = args

    def __neg__(self) -> 'MathExpr':
        raise NotImplementedError

    def __contains__(self, item: 'MathExpr') -> bool:
        raise NotImplementedError

    def converted(self, replace_function: tp.Callable[['MathExpr'], 'MathExpr']) -> 'MathExpr':
        raise NotImplementedError

    def simplified(self, facts: tp.Dict['Attribute', 'MathExpr'] = None) -> 'MathExpr':
        raise NotImplementedError

    def to_bytes(self) -> 'MathExpr':
        raise NotImplementedError


class Read(Attribute):
    def __init__(self, name: str, channel: str) -> None:
        super().__init__(name)
        self.channel = channel


class Write(Attribute, Action):
    def __init__(self, name: str, channel: str, item: Expr) -> None:
        super().__init__(name)
        self.channel = channel
        self.item = item


class ActionParser:
    def __init__(self) -> None:
        identifier = Word(alphanums + "_")
        identifier.setParseAction(parse_identifier)
        literal = Word(alphanums + "_")
        literal.setParseAction(parse_literal)

        boolean_literal = Keyword("True") | Keyword("False")
        boolean_literal.setParseAction(parse_booleanliteral)

        string = sglQuotedString | dblQuotedString
        string.setParseAction(parse_string)

        lpr = Suppress(Literal("("))
        rpr = Suppress(Literal(")"))

        variable = Word(alphas, exact=1) + Optional(Word(alphanums + "_"))
        variable.setParseAction(parse_variable)

        multi_arg_func: Forward = Forward()
        arg = multi_arg_func | Parser.numeric_literal() | variable | string
        multi_arg_func <<= Word(alphanums + "_") + lpr + Optional(delimitedList(arg)) + rpr
        multi_arg_func.setParseAction(parse_func)

        read = (Word(alphanums + "_") + Suppress(Literal("'"))
                + Suppress(Literal("Read")) + lpr + Word(alphanums + "_") + rpr)
        read.setParseAction(parse_read)

        variable_attribute = Word(alphas) + Literal(".") + Word(alphanums + "_")
        variable_attribute.setParseAction(parse_variable_attribute)

        write = (Word(alphanums + "_") + Suppress(Literal("'")) + Suppress(Literal("Write"))
                 + lpr + Word(alphanums + "_") + Suppress(Literal(","))
                 + (multi_arg_func | variable) + rpr)
        write.setParseAction(parse_write)



        assignment = (identifier + Keyword(":=")
                      + (boolean_literal | string | Parser.numeric_literal() | variable_attribute
                         | read | multi_arg_func | Parser.mathematical_expression()
                         | variable | literal))
        assignment.setParseAction(parse_assignment)

        self.grammar = write | assignment

    def parse(self, string: str) -> Action:
        return self.grammar.parseString(string)[0]


def parse_assignment(tokens: ParseResults) -> Assignment:
    return Assignment(tokens[0], tokens[2])


def parse_identifier(tokens: ParseResults) -> Identifier:
    return Identifier(tokens[0])


def parse_literal(tokens: ParseResults) -> Value:
    return Value(tokens[0])


def parse_booleanliteral(tokens: ParseResults) -> BooleanLiteral:
    return BooleanLiteral(tokens[0])


def parse_string(tokens: ParseResults) -> String:
    return String(tokens[0][1:-1])


def parse_func(tokens: ParseResults) -> Function:
    return Function(tokens[0], tokens[1:])


def parse_variable(tokens: ParseResults) -> Value:
    tokens[0] = "".join(tokens)
    return Value(tokens[0])


def parse_read(tokens: ParseResults) -> Read:
    return Read(tokens[0], tokens[1])


def parse_write(tokens: ParseResults) -> Write:
    return Write(tokens[0], tokens[1], tokens[2])


def parse_variable_attribute(tokens: ParseResults) -> Value:
    tokens[0] = ("".join(tokens[0:]))
    return Value(tokens[0])
