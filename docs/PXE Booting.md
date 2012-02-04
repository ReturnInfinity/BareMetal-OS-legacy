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

At this point we can verify if the DCHP and TFTP services are running correctly. Create a new VM within VirtualBox? with no Hard Drive. Configure a single NIC to be on the private network and set the boot order to Network first.

On bootup of the new VM you should see this: 

This shows the the VM successfully connected to our DHCP server and tried to download the file from the TFTP server. The failure is due to us not building and placing the file yet.

## Download and build the Pure64 and BareMetal OS source

Now we will grab the Pure64 and BareMetal OS source code:

svn checkout http://baremetal.googlecode.com/svn/trunk/ baremetal
svn checkout http://pure64.googlecode.com/svn/trunk/ pure64

	cd pure64/bootsectors

	nasm pxestart.asm -o ../../pxestart.bin

	cd ..

Modify Pure64 so that it will work via PXE.

Comment the following line in `pure64.asm`:

	call hdd_setup

Now compile Pure64 and the Kernel:

	nasm pure64.asm -o ../pure64.sys

	cd ../baremetal/os/

	nasm kernel64.asm -o ../../kernel64.sys

	cd ../..

	cat pxestart.bin pure64.sys kernel64.sys > pxeboot.bin

The default TFTP directory is located at `/var/lib/tftpboot`

	sudo copy pxeboot.bin /var/lib/tftpboot/

Reboot the PXE boot VM.