import unittest

from rflx.expression import Add, Number, Value
from tools.action_parser import (FALSE, Action, ActionParser, Assignment, Call, Read, String,
                                 Variable, Write)


class TestActionParser(unittest.TestCase):  # pylint: disable=too-many-public-methods
    def setUp(self) -> None:
        self.maxDiff = None  # pylint: disable=invalid-name
        self.parser = ActionParser()

    def assert_action(self, string: str, expected: Action) -> None:
        self.assertEqual(self.parser.parse(string), expected)

    def test_assignement_literal(self) -> None:
        self.assert_action('server_certificate_type := X509',
                           Assignment('server_certificate_type', Variable('X509')))

    def test_assignment_boolean(self) -> None:
        self.assert_action('server_name_received := False',
                           Assignment('server_name_received', FALSE))

    def test_assignement_numeral(self) -> None:
        self.assert_action('legacy_version := 772',
                           Assignment('legacy_version', Number(772)))

    def test_assignement_string(self) -> None:
        self.assert_action(
            'label := \'c e traffic\'',
            Assignment('label', String('c e traffic')))

    def test_assignement_numeral_hex(self) -> None:
        self.assert_action('legacy_version := 16#0304#',
                           Assignment('legacy_version', Number(772)))

    def test_assignement_numeral_bin(self) -> None:
        self.assert_action('legacy_version := 2#1100000100#',
                           Assignment('legacy_version', Number(772)))

    def test_assignment_function(self) -> None:
        self.assert_action('connection := read(application_in)',
                           Assignment('connection',
                                      Call('read', [Variable('application_in')])))

    def test_assignment_function_no_arg(self) -> None:
        self.assert_action('connection := fun()',
                           Assignment('connection', Call('fun', [])))

    def test_assignment_function_multiple_args(self) -> None:
        self.assert_action('derived_early_secret := Derive_Secret(early_secret, \'derived\', \'\')',
                           Assignment('derived_early_secret',
                                      Call('Derive_Secret',
                                           [Variable('early_secret'),
                                            String('derived'),
                                            String('')])))

    def test_assignment_nested_functions(self) -> None:
        self.assert_action('extensions_list := list(supported_versions_extension(list(772)))',
                           Assignment('extensions_list',
                                      Call('list',
                                           [Call('supported_versions_extension',
                                                 [Call('list', [Number(772)])])])))

    def test_assignment_nested_functions_multiple_args(self) -> None:
        self.assert_action('extensions_list := append(extensions_list, '
                           'supported_groups_extension(configuration))',
                           Assignment('extensions_list',
                                      Call('append',
                                           [Variable('extensions_list'),
                                            Call('supported_groups_extension',
                                                 [Variable('configuration')])])))

    def test_assignment_attribute_read(self) -> None:
        self.assert_action('Control_Message := GreenTLS_Control\'Read (control_in)',
                           Assignment('Control_Message',
                                      Read('GreenTLS_Control', 'control_in')))

    def test_assignment_attribute_write(self) -> None:
        self.assert_action('TLS_Alert\'Write (network_out, TLS_Alert (CLOSE_NOTIFY))',
                           Write('TLS_Alert', 'network_out',
                                 Call('TLS_Alert', [Variable('CLOSE_NOTIFY')])))

    def test_assignment_variable(self) -> None:
        self.assert_action('client_write_key := KeyMessage.client_write_key',
                           Assignment('client_write_key',
                                      Variable('KeyMessage', ['client_write_key'])))

    def test_assignment_math_expression(self) -> None:
        self.assert_action('server_sequence_number := server_sequence_number + 1',
                           Assignment('server_sequence_number',
                                      Add(Value('server_sequence_number'), Number(1))))
