test: check-python

check-python:
	mypy */*.py
	pylint */*.py
	flake8 */*.py
