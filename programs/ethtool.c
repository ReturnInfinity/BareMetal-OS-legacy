#include "libBareMetal.h"

void ethtool_send();
void ethtool_receive();

int running = 1;
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
			ethtool_send();
		else if (key == 'q')
			running = 0;
	}

	b_system_config(networkcallback_set, 0);

	return 0;
}

void ethtool_send()
{
	b_output("\nSending packet, ");
	b_output("Sent!");
}

void ethtool_receive()
{
	b_output("\nReceived packet");
}
