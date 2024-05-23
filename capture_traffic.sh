#!/bin/bash

# Directory to store capture files
capture_dir="/capture/file/location"

# File to store the last used decimal number
counter_file="/etc/capture_counter.txt"

# Maximum number of files to keep
max_files=100

# Create the counter file if it doesn't exist
touch "$counter_file"

# Change permissions of the counter file to 700
chmod 700 "$counter_file"

# Function to increment decimal number
increment_num() {
    printf "%04d" $((10#$1 + 1))
}

# Function to get the last used decimal number
get_last_num() {
    if [ -f "$counter_file" ]; then
        cat "$counter_file"
    else
        echo "0"
    fi
}

# Function to remove excess files if more than max_files exist
remove_excess_files() {
    find "$capture_dir" -type f -name "capture_*.pcap" -print0 | sort -zrn | tail -zn +"$max_files" | xargs -0 rm
}

# Function to start tcpdump
start_tcpdump() {
    remove_excess_files
    num=$(get_last_num)
    while true; do
        capture_file="$capture_dir/capture_$num.pcap"
        /usr/sbin/tcpdump -tttt -i eth1 -C 1000 -w "$capture_file"
        num=$(increment_num $num)
        echo "$num" > "$counter_file"
    done
}

# Function to handle cleanup
cleanup() {
    echo "Cleaning up..."
    # Increment the counter before saving to file
    num=$(increment_num $num)
    echo "$num" > "$counter_file"
    # Kill the tcpdump process
    pkill tcpdump
    exit 0
}

# Trap Ctrl+C signal
trap cleanup SIGINT

# Run tcpdump
start_tcpdump
