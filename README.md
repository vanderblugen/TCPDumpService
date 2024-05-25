# tcpdump as a service
This is a basic how to for setting up tcpdump to passively monitor network traffic.
In this instance, it is implemented thru a Raspberry Pi using Raspbian Buster Version 10 on a dedicated ethernet interface of eth1.

This service creates pcap files named capture_RRRRRRRR.pcap, where R is a lowercase alphanumeric character, in the /file/location folder.
Files are 1GB of maximum size and 100 total pcap files are kept.  The oldest files will start to be deleted once that number is exceeded.

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
capture_dir="/file/location"

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
