# PXE Booting

Intro goes here!

## Creating the PXE boot environment
Now that BareMetal OS supports the Intel 8254x (Intel Pro/1000) Gigabit network chipset it is possible to set up a network environment in VirtualBox?

In this example we will use a Linux VM with 2 NIC's. One on the regular network (set to bridged mode, eth0) and one set to private (Internal Network, eth1)

Install Linux in a 64 bit VM. In this example we used Ubuntu 11.10 64-bit. Add dhcp3-server and tftpd-hpa. Also grab NASM.

Ubuntu:

	sudo apt-get install dhcp3-server tftpd-hpa nasm

In Debian/Ubuntu the config for tftpd is located at `/etc/default/tftpd-hpa`. In Fedora/Redhat the config for tftpd is located at `/etc/xinetd.d/tftp`

Configure eth1 to a manual IP (192.168.242.1, 255.255.255.0)

Open a command line

	sudo nano -w /etc/default/isc-dhcp-server

enter the interface name in "INTERFACES". Enter `eth1`

	sudo nano -w /etc/dhcp/dhcpd.conf

Add the following:

	subnet 192.168.242.0 netmask 255.255.255.0 {
	    range 192.168.242.10 192.168.242.159;
	    filename "pxeboot.bin";
	}

Now start the DHCP server:

	sudo service isc-dhcp-server restart

At this point we can verify if the DCHP and TFTP services are running correctly. Create a new VM within VirtualBox with no Hard Drive. Configure a single NIC to be on the private network and set the boot order to Network first.


## Download and build the Pure64 and BareMetal OS source

Now we will grab the Pure64 and BareMetal OS source code and extract it:

Build Pure64:

	cd Pure64
	./build.sh
	cp pxeboot.sys ../
	cp pure64.sys ../
	cd ..

Build BareMetal OS:

In kernel64.asm you will need to comment or delete the line with "call init_hdd".

	cd BareMetal-OS
	./build.sh
	cp kernel64.sys ../
	cd ..

Prepare the PXE boot file:

The default TFTP directory is located at `/var/lib/tftpboot`

	cat pxestart.sys pure64.sys kernel64.sys > pxeboot.bin
	sudo cp pxeboot.bin /var/lib/tftpboot/

Reboot the PXE boot VM.