import unittest

from rflx.expression import Number

from tools.action_parser import (Action, ActionParser, Assignment, BooleanLiteral, Function,
                                 Identifier, Literaldef, String, Variable)


class TestActionParser(unittest.TestCase):  # pylint: disable=too-many-public-methods
    def setUp(self) -> None:
        self.maxDiff = None  # pylint: disable=invalid-name
        self.parser = ActionParser()

    def assert_action(self, string: str, expected: Action) -> None:
        self.assertEqual(self.parser.parse(string), expected)

    def test_assignement_literal(self) -> None:
        self.assert_action('server_certificate_type := X509',
                           Assignment(Identifier("server_certificate_type"), Literaldef("X509")))

    def test_assignment_boolean(self) -> None:
        self.assert_action('server_name_received := False',
                           Assignment(Identifier("server_name_received"), BooleanLiteral("False")))

    def test_assignement_numeral(self) -> None:
        self.assert_action('legacy_version := 772',
                           Assignment(Identifier("legacy_version"), Number(772)))

    def test_assignement_string(self) -> None:
        self.assert_action(
            'label := "c e traffic"',
            Assignment(Identifier("label"), String("c e traffic")))

    def test_assignement_numeral_hex(self) -> None:
        self.assert_action('legacy_version := 16#0304#',
                           Assignment(Identifier("legacy_version"), Number(772)))

    def test_assignement_numeral_bin(self) -> None:
        self.assert_action('legacy_version := 2#1100000100#',
                           Assignment(Identifier("legacy_version"), Number(772)))

    def test_assignment_function(self) -> None:
        self.assert_action('connection := read(application_in)',
                           Assignment(Identifier("connection"),
                                      Function('read', [Variable('application_in')])))

    def test_assignment_function_no_arg(self) -> None:
        self.assert_action('connection := null()',
                           Assignment(Identifier("connection"), Function("null", [])))

    def test_assignment_function_multiple_args(self) -> None:
        self.assert_action('derived_early_secret := Derive_Secret(early_secret,"derived","")',
                           Assignment(Identifier("derived_early_secret"),
                                      Function('Derive_Secret',
                                               [Variable('early_secret'),
                                                String("derived"), String("")])))

    def test_assignment_nested_functions(self) -> None:
        self.assert_action('extensions_list := list(supported_versions_extension(list(772))))',
                           Assignment(Identifier("extensions_list"),
                                      Function("list",
                                               [Function('supported_versions_extension',
                                                         [Function('list', [Number(772)])])])))

    def test_assignment_nested_functions_multiple_args(self) -> None:
        self.assert_action('extensions_list := append(extensions_list, '
                           'supported_groups_extension(configuration))',
                           Assignment(Identifier('extensions_list'),
                                      Function('append',
                                               [Variable('extensions_list'),
                                                Function('supported_groups_extension',
                                                         [Variable('configuration')])])))
