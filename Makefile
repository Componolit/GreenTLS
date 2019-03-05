test: check-python

check-python:
	mypy */*.py
	pylint */*.py
	flake8 */*.py
	isort -c -w 100 */*.py
	coverage run -m unittest
