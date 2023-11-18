#!/usr/bin/env python3
import os
import subprocess
from sys import exit

# Define the path to the directory containing input text files
tests_dir = "testsParser"

dune_command = "dune exec alpaca -- -a"


input_files = [f for f in os.listdir(tests_dir) if f.endswith(".in")]
input_files.sort()
if not input_files:
    print("No input tests found")
    exit(2)

expected_output_files = [f for f in os.listdir(tests_dir) if f.endswith(".out")]

input_error_files = [f for f in os.listdir(tests_dir) if f.endswith(".in.bad")]
expected_output_error_files = [f for f in os.listdir(tests_dir) if f.endswith(".out.bad")]

input_error_files.sort()
expected_output_files.sort()
expected_output_error_files.sort()

#print(input_error_files)
#print(expected_output_error_files)
fail = False
# testing "positive" file inputs
for input_file, expected_output_file in \
        zip(input_files, expected_output_files):
    input_path = os.path.join(tests_dir, input_file)
    expected_output_path = os.path.join(tests_dir, expected_output_file)
    
    if os.path.exists(expected_output_path):
        process = subprocess.run(dune_command + " " + input_path, capture_output=True, text=True, shell=True)
        output = process.stdout

        with open(expected_output_path, 'r') as f:
            expected_output = f.read()

        if output == expected_output:
            print(f"Test passed for {input_file}")
        else:
            print(f"Test failed for {input_file} (stdout differed)")
            fail = True

    else:
        print(f"Expected output file for {input_file} not found.")
        fail = True

# testing "negative" file inputs
for input_file, expected_error_file in zip(input_error_files,expected_output_error_files) :
    input_path = os.path.join(tests_dir, input_file)
    expected_error_path = os.path.join(tests_dir, expected_error_file)
    if os.path.exists(expected_output_path):
        process = subprocess.run(dune_command + " " + input_path, capture_output=True, text=True, shell=True)
        output = process.stderr.strip()
        with open(expected_error_path, 'r') as f:
            expected_output = f.read().strip()
        if output == expected_output:
             print(f"Test passed for {input_file}")
        else:
             print(f"Incorrect error message produced for {input_file}")
             fail = True


if fail:
    print("Not all tests passed :(")
    exit(1)
else:
    print("All tests passed!")
    exit(0)