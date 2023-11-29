#!/usr/bin/env python3
import subprocess
import os
import sys

compile_command = "dune exec alpaca -- -c {}"
tests_dir = "tests/bad"

tests_dir_files = os.listdir(tests_dir)
tests_dir_files.sort()
input_error_files = [f for f in tests_dir_files if f.endswith(".alp")]
expected_output_error_files = [f for f in tests_dir_files if f.endswith(".out")]

if len(input_error_files) != len(expected_output_error_files):
    print(f"{tests_dir} directory contents invalid!", file=sys.stderr)
    sys.exit(1)

fail = False

# testing "negative" file inputs
for input_file, expected_error_file in zip(input_error_files,expected_output_error_files) :
    input_path = os.path.join(tests_dir, input_file)
    expected_error_path = os.path.join(tests_dir, expected_error_file)
    process = subprocess.run(compile_command.format(input_path), capture_output=True, text=True, shell=True)
    output = process.stderr.strip()
    with open(expected_error_path, 'r') as f:
        expected_output = f.read().strip()
    if output == expected_output:
        print(f"Test passed for {input_file}")
    else:
        print(f"Incorrect error message produced for {input_file}\nExpected:\n{expected_output}\nGot:\n{output}\n")
        fail = True

if fail:
    print("Not all negative tests passed :(")
    sys.exit(1)
else:
    print("All negative tests passed!")
    sys.exit(0)