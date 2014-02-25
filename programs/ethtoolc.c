// gcc -c -m64 -nostdlib -nostartfiles -nodefaultlibs -o ethtoolc.o ethtoolc.c
// gcc -c -m64 -nostdlib -nostartfiles -nodefaultlibs -o libBareMetal.o libBareMetal.c
// ld -T app.ld -o ethtoolc.app ethtoolc.o libBareMetal.o

#include "libBareMetal.h"

void ethtool_send();
void ethtool_receive();

char packet[1500];

int running = 1, len = 0;
char key;

int main(void)
{
	b_output("EthTool: S to send a packet, Q to quit.\nReceived packets will display automatically.");
	// Configure the network callback
	b_system_config(networkcallback_set, (unsigned long int)ethtool_receive);

	while (running == 1)
	{
		key = b_input_key();
		if (key == 's')
		{
			ethtool_send();
		}
		else if (key == 'q')
		{
			running = 0;
		}
	}

	b_output("\n");
	// Clear the network callback
	b_system_config(networkcallback_set, 0);

	return 0;
}

void ethtool_send()
{
	b_output("\nSending packet, ");
	b_ethernet_tx(packet, 1500);
	b_output("Sent!");
}

void ethtool_receive()
{
	b_output("\nReceived packet\n");
	len = b_ethernet_rx(packet);
	b_system_misc(debug_dump_mem, packet, len);
}
