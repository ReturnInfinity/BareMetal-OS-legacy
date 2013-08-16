#include "libBareMetal.h"

void clear_screen();
void put_pixel(unsigned int x, unsigned int y, unsigned char red, unsigned char blue, unsigned char green);

unsigned long VideoBase, VideoX, VideoY, VideoBPP;

int main()
{
	VideoBase = b_system_config(20, 0);
	VideoX = b_system_config(21, 0);
	VideoY = b_system_config(22, 0);
	VideoBPP = b_system_config(23, 0);

	clear_screen();
	put_pixel(100,100,255,255,255);
}

void clear_screen()
{
	char* VideoMemory = (char*)VideoBase;
	int bytes = VideoX * VideoY * (VideoBPP >> 3);
	int offset = 0;
	for (offset=0; offset<bytes; offset++)
		VideoMemory[offset] = 0x00;
}

void put_pixel(unsigned int x, unsigned int y, unsigned char red, unsigned char blue, unsigned char green)
{
	char* VideoMemory = (char*)VideoBase;
	int offset = 0;
	offset = (y * VideoX + x) * (VideoBPP >> 3);
	VideoMemory[offset] = red;
	VideoMemory[offset+1] = blue;
	VideoMemory[offset+2] = green;
}
