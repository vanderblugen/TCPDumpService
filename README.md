# tcpdump as a service
This is a basic how to for setting up tcpdump to passively monitor network traffic.

In this instance, it is implemented thru a Raspberry Pi using Raspbian Buster Version 10 on a dedicated ethernet interface of eth1.

## Configure ethernet connection
### Determine the ethernet adapter interface that is going to be used
```shell
ifconfig
```
<img src="ifconfig.jpg">

### Put adapter in promiscuous mode
Promiscuous mode will allow the adapter to read all traffic allong the line that it can, even if it is not meant for it

#### Make a backup of `dhcpcd.conf`
```shell
sudo cp /etc/dhcpcd.conf /etc/dhcpcd.conf.bak
```
#### Set the address of nothing to the specified adapter
```shell
echo 'static' >> /etc/dhcpcd.conf
echo 'interface eth1' >> /etc/dhcpcd.conf
echo 'static ip_address=0.0.0.0' >> /etc/dhcpcd.conf
```
#### To for changes to take effect
```shell
sudo reboot now
```
## Create a sh file
Create <a href="capture_traffic.sh">capture_traffic.sh</a> file
```shell
sudo nano /etc/capture_traffic.sh
```
Paste the sh file in there
```
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
```
To Save `Ctrl+X and Y and <Enter>`

Update the permissions of the sh file

```shell
sudo chmod 700 /etc/capture_traffic.sh
```
### Create a service file
Create <a href="promisc.service">promisc.service</a> file
```shell
sudo nano /etc/systemd/system/promisc.service
```
Paste the service file in there
```shell
[Unit]
Description=Put an interface in promiscuous mode during bootup
After=network.target

[Service]
Type=oneshot
ExecStart=/bin/ip link set eth1 promisc on
TimeoutStartSec=0
RemainAfterExit=yes

[Install]
WantedBy=default.target
```
To Save `Ctrl+X and Y and <Enter>`

Reload the services, enable the newly created service past reboot, and starts it
```shell
sudo systemctl daemon-reload
sudo systemctl enable promisc
sudo systemctl start promisc
```


## Install and configure tcpdump
### Install tcpdump
If `tcpdump` isn't already installed, it needs to be
```shell
sudo apt-get install tcpdump -y
```

### Setup the tcpdump service
Create the <a href="tcpdumpsvc.service">tcpdumpsvc.service</a> file
```shell
sudo nano /etc/systemd/system/tcpdumpsvc.service
```

Paste the service file in nano.  Make sure that the parameters of ExecStart look correct.
```shell
[Unit]
Description=Tcpdump service
After=network.target

[Service]
Type=simple
User=root
ExecStart=/etc/capture_traffic.sh
WorkingDirectory=/file/store/location
Restart=on-failure
RestartSec=30
TimeoutStartSec=60
TimeoutStopSec=30
ExecStop=/bin/kill -s QUIT $MAINPID

[Install]
WantedBy=multi-user.target
```
To Save `Ctrl+X and Y and <Enter>`

In that Service file:
* `-v` is verbose output
* `-tttt` is print a timestamp, as hours, minutes, seconds, and fractions of a second since midnight, preceded by the date, on each dump line.
* `-i eth1` is the interface that it's pulling from
* `-w /location/file` is the file that it's reading into
* `-C 1000` is the size of the files in megabytes rounded to 1,000,000
* More informaton on tcpdump can be found https://www.tcpdump.org/manpages/tcpdump.1.html

To Save `Ctrl+X and Y and <Enter>`

Like before, reload the services, enable the newly created service past reboot, and start it
```shell
sudo systemctl daemon-reload
sudo systemctl enable tcpdumpsvc
sudo systemctl start tcpdumpsvc
```

Verify the service is running
```shell
sudo service tcpdump status
```

The files should also be being created at this point as well

All Set


## If anyone wants to contribute please reach out
