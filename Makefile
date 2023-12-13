
# "make all" builds the executable

CC = gcc
LLC = llc

NATIVE_MODULES = registry.o

.PHONY : all
all : ./_build/default/bin/alpaca.exe

# "make test" Compiles everything and runs the regression tests

TESTS = $(wildcard tests/*.alp)
.PHONY : testall
testall : $(TESTS:%.alp=%.exe)
	./testAlpaca.py $^
	./testAlpacaNegative.py

.PHONY : test_%.exe
test_%.exe : tests/%.exe
	./testAlpaca.py $<

# "make" will just compile the Alpaca compiler

./_build/default/bin/alpaca.exe : bin/parser.mly bin/scanner.mll bin/codegen.ml bin/semant.ml bin/alpaca.ml
	dune build
	touch $@

# Build rules for native modules

registry.o : registry.c
	$(CC) -c -o $@ $<

# "make clean" removes all generated files

.PHONY : clean
clean :
	dune clean
	rm -rf testall.log *.diff *.o alpaca.opam
	rm *.exe tests/*.exe *.ll *.s tests/*.ll tests/*.s

%.ll: %.alp ./_build/default/bin/alpaca.exe
	./_build/default/bin/alpaca.exe -c $< > $@

%.s: %.ll
	$(LLC) "-relocation-model=pic" -o $@ $<

%.o: %.s
	$(CC) -c -x assembler -o $@ $<

%.exe: %.o $(NATIVE_MODULES)
	$(CC) -o $@ $< $(NATIVE_MODULES)

# %.exe: %.alp ./_build/default/bin/alpaca.exe $(NATIVE_MODULES)
# 	./_build/default/bin/alpaca.exe -c $< | $(LLC) "-relocation-model=pic" | $(CC) -x assembler -o $@ - $(NATIVE_MODULES)
