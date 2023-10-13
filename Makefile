
# "make all" builds the executable as well as the "printbig" library designed
# to test linking external code

.PHONY : all
all : ./_build/default/bin/microc.exe printbig.o

# "make test" Compiles everything and runs the regression tests

.PHONY : test
test : all testall.sh
	./testall.sh

# "make" will just compile the MicroC compiler along with printbig.c

./_build/default/bin/microc.exe : bin/parser.mly bin/scanner.mll bin/codegen.ml bin/semant.ml bin/microc.ml
	dune build

# "make printbig" compiles the helper C file for the printbig built-in

printbig : printbig.c
	cc -o printbig -DBUILD_TEST printbig.c

# "make clean" removes all generated files

.PHONY : clean
clean :
	dune clean
	rm -rf testall.log *.diff printbig.o microc.opam


# Building the zip

TESTS = \
  add1 arith1 arith2 arith3 fib float1 float2 float3 for1 for2 func1 \
  func2 func3 func4 func5 func6 func7 func8 func9 gcd2 gcd global1 \
  global2 global3 hello if1 if2 if3 if4 if5 if6 local1 local2 ops1 \
  ops2 ops3 printbig var1 var2 while1 while2

FAILS = \
  assign1 assign2 assign3 dead1 dead2 expr1 expr2 expr3 float1 float2 \
  for1 for2 for3 for4 for5 func1 func2 func3 func4 func5 func6 func7 \
  func8 func9 global1 global2 if1 if2 if3 nomain printbig printb print \
  return1 return2 while1 while2

TESTFILES = $(TESTS:%=test-%.mc) $(TESTS:%=test-%.out) \
	    $(FAILS:%=fail-%.mc) $(FAILS:%=fail-%.err)

ZIPFILES = bin Dockerfile dune-project lib Makefile \
	README testall.sh printbig.c \
	$(TESTFILES:%=tests/%) 

microc.zip : $(ZIPFILES)
	cd .. && zip -r microc/microc.zip \
		$(ZIPFILES:%=microc/%)
