.PHONY: test get publish analyze format

test:
	flutter pub run test test

get:
	flutter pub get

publish:
	flutter pub publish --dry-run

analyze:
	flutter analyze

format:
	flutter format .
