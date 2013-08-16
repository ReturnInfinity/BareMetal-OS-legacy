#include "libBareMetal.h"

void clear_screen();
void put_pixel(unsigned int x, unsigned int y, unsigned char red, unsigned char blue, unsigned char green);

unsigned long VideoX, VideoY, VideoBPP;
char* VideoMemory;

int main()
{
	VideoMemory = (char*)b_system_config(20, 0);
	VideoX = b_system_config(21, 0);
	VideoY = b_system_config(22, 0);
	VideoBPP = b_system_config(23, 0);

	clear_screen();

	put_pixel(100,100,255,255,255);
}

void clear_screen()
{
	int offset = 0;
	int bytes = VideoX * VideoY;

	if (VideoBPP == 24)
	{
		bytes = bytes * 3;
	}
	else if (VideoBPP == 32)
	{
		bytes = bytes * 4;
	}

	for (offset=0; offset<bytes; offset++)
		VideoMemory[offset] = 0x00;
}

void put_pixel(unsigned int x, unsigned int y, unsigned char red, unsigned char blue, unsigned char green)
{
	int offset = 0;
	offset = y * VideoX + x;
	if (VideoBPP == 24)
	{
		offset = offset * 3;
		VideoMemory[offset] = red;
		VideoMemory[offset+1] = blue;
		VideoMemory[offset+2] = green;
	}
	else if (VideoBPP == 32)
	{
		offset = offset * 4;
		VideoMemory[offset] = 0x00;
		VideoMemory[offset+1] = red;
		VideoMemory[offset+3] = blue;
		VideoMemory[offset+4] = green;
	}
}
