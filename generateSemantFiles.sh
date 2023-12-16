#!/bin/bash

# Directory containing the input files
dir="testsSemant"

# For each file in the directory
for file in "$dir"/*; do
  # Get the base name of the file (without the directory part)
  base=$(basename "$file")

  # Check if the file ends with ".in.bad"
  if [[ $file == *.in.bad ]]; then
    # If it does, make the output file end with ".out.bad"
    base=${base%.in.bad}
    outfile="$dir/$base.out.bad"
    # Use 2> to redirect stderr to the output file
    dune exec alpaca -- -s < "$file" 2> "$outfile"
  else
    # Otherwise, make the output file end with ".out"
    outfile="$dir/$base.out"
    # Use > to redirect stdout to the output file
    dune exec alpaca -- -s < "$file" > "$outfile"
  fi
done