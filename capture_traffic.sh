#!/bin/bash

# Directory to store capture files
capture_dir="/media/Captures"

# Maximum number of files to keep
max_files=99

# Function to remove excess files if the count exceeds max_files
remove_excess_files() {
  excess_files=$(ls "$capture_dir"/*.pcap 2>/dev/null | wc -l)
  if [ $excess_files -gt $max_files ]; then
    echo "Removing $((excess_files - max_files)) excess files..."
    ls -t "$capture_dir"/*.pcap | tail -n $((excess_files - max_files)) | xargs rm -f
  fi
}

# Function to start tcpdump
start_tcpdump() {
  while true; do
    # Run verification to remove excess files if needed
    remove_excess_files
    # Generate random filename
    next_file_name="capture_$(openssl rand -hex 4).pcap"
    echo "Starting tcpdump. Output file: $capture_dir/$next_file_name"
    /usr/sbin/tcpdump -tttt -i eth1 -C 1000 -w "$capture_dir/$next_file_name" &
    wait $!
  done
}

# Function to handle cleanup
cleanup() {
  echo "Cleaning up..."
  pkill -P $$ tcpdump && echo "Successfully killed tcpdump process" || echo "Error: Unable to kill tcpdump process"
  exit 0
}

# Trap Ctrl+C signal
trap cleanup SIGINT

# Run tcpdump
start_tcpdump
