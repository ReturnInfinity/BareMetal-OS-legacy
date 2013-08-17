/*
3D stars!
gcc -I newlib-2.0.0/newlib/libc/include/ -c 3dstars.c -o 3dstars.o
ld -T app.ld -o 3dstars.app crt0.o 3dstars.o libBareMetal.o libc.a libm.a
*/

#include <math.h>
#include <stdlib.h>
#include <string.h>
#include "libBareMetal.h"

void clear_screen();
void put_pixel(unsigned int x, unsigned int y, unsigned char red, unsigned char blue, unsigned char green);

unsigned long VideoX, VideoY, VideoBPP;
char* VideoMemory;
int numstars = 1000;
int PER = 256;

typedef struct {
	double x, y, z;
	int dx, dy;
} stardata;

int main()
{
	int n, dx, dy;
	double x, y, z, rx, ry, rz;
	double rads = 360 / (2 * M_PI);
	double sind1, cosd1, sind2, cosd2;
	stardata star[numstars];
	float a1=0, a2=0, zval=0;

	VideoMemory = (char*)b_system_config(20, 0);
	VideoX = b_system_config(21, 0);
	VideoY = b_system_config(22, 0);
	VideoBPP = b_system_config(23, 0);

	for (n=0; n<numstars; n++)
	{
		star[n].x = rand();
		if (rand() > RAND_MAX / 2)
			star[n].x *= -1;
		star[n].y = rand();
		if (rand() > RAND_MAX / 2)
			star[n].y *= -1;
		star[n].z = rand();
		if (rand() > RAND_MAX / 2)
			star[n].z *= -1;
	}

	clear_screen();

	while(1)
	{
		sind1 = sin(a1/rads);
		cosd1 = cos(a1/rads);
		sind2 = sin(a2/rads);
		cosd2 = cos(a2/rads);

		for (n=0; n<numstars; n++)
		{
			x = star[n].x;
			y = star[n].y;
			z = star[n].z;

			rx = (x * cosd1) - (z * sind1);
			rz = (x * sind1) + (z * cosd1);
			ry = (y * cosd2) - (rz * sind2);
			rz = (y * sind2) + (rz * cosd2);

			zval = rz + 1000;

			star[n].dx = (VideoX / 2) + ((PER * rx) / zval);
			star[n].dy = (VideoY / 2) + ((PER * ry) / zval);
		}
		a1+=0.01;
		a2+=0.00001;
		clear_screen();
		for (n=0; n<numstars; n++)
		{
			if (star[n].dx >= 0 && star[n].dx < VideoX && star[n].dy >= 0 && star[n].dy < VideoY)
				put_pixel(star[n].dx, star[n].dy, 255, 255, 255);
		}
	}
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

//	for (offset=0; offset<bytes; offset++)
//		VideoMemory[offset] = 0x00;
	memset(VideoMemory, 0x00, bytes);
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
