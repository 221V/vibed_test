

# todo clean

c:
	dub build --compiler ldc2

c2:
	dub build --compiler ldc2 --build release --force

run:
	./vtest



default: run

.PHONY: c c2 run

