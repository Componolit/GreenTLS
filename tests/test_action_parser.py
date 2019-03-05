import unittest

from tools.action_parser import Action, ActionParser


class TestActionParser(unittest.TestCase):  # pylint: disable=too-many-public-methods
    def setUp(self) -> None:
        self.maxDiff = None  # pylint: disable=invalid-name
        self.parser = ActionParser()

    def assert_action(self, string: str, expected: Action) -> None:
        self.assertEqual(self.parser.parse(string), expected)

    def test_assignement_literal(self) -> None:
        self.assert_action('server_certificate_type := X509',
                           Action())

    def test_assignment_boolean(self) -> None:
        self.assert_action('server_name_received := False',
                           Action())

    def test_assignement_numeral(self) -> None:
        self.assert_action('legacy_version := 772',
                           Action())

    def test_assignement_string(self) -> None:
        self.assert_action('label := "c e traffic"',
                           Action())

    def test_assignement_numeral_hex(self) -> None:
        self.assert_action('legacy_version := 16#0304#',
                           Action())

    def test_assignement_numeral_bin(self) -> None:
        self.assert_action('legacy_version := 2#1100000100#',
                           Action())

    def test_assignment_function(self) -> None:
        self.assert_action('connection := read(application_in)',
                           Action())

    def test_assignment_function_no_arg(self) -> None:
        self.assert_action('connection := null()',
                           Action())

    def test_assignment_function_multiple_args(self) -> None:
        self.assert_action('derived_early_secret := Derive_Secret(early_secret, "derived", "")',
                           Action())

    def test_assignment_nested_functions(self) -> None:
        self.assert_action('extensions_list := list(supported_versions_extension(list(772))))',
                           Action())

    def test_assignment_nested_functions_multiple_args(self) -> None:
        self.assert_action('extensions_list := append(extensions_list, '
                           'supported_groups_extension(configuration))',
                           Action())
