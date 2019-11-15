# TCPDumpAsService
This is a basic how to for setting up tcpdump to passively montior network traffic.
In this instance, it is implemented thru a Raspberry Pi using Raspbian Buster Version 10 on a dedicated ethernet interface.

## Install tcpdump
If `tcpdump` isn't already installed, it needs to be
```shell
sudo apt-get install tcpdump
```
## Configure ethernet connection
### Determine the ethernet adapter interface that is going to be used
```shell
ifconfig
```
<img src="ifconfig.jpg">

### Put adapter in promiscuous mode
Promiscuous mode will allow the adapter to read all traffic, even if it is not meant for it

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
#### To take effect
```shell
sudo reboot now
```

-i eth1 is the interface that it's pulling from
-w /location/file is the file that it's reading into
-W is the number of files
-C is the size of the files in megabytes rounded to 1,000,000

Learning more about tcpdump can be found https://www.tcpdump.org/manpages/tcpdump.1.html

