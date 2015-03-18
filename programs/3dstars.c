/*
3D stars!
gcc -I newlib-2.1.0/newlib/libc/include/ -c 3dstars.c -o 3dstars.o
ld -T app.ld -o 3dstars.app crt0.o 3dstars.o libBareMetal.o libc.a libm.a
*/

#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "libBareMetal.h"

void clear_screen();
void put_pixel(unsigned int x, unsigned int y, unsigned char red, unsigned char blue, unsigned char green);

unsigned long VideoX, VideoY, VideoBPP, VideoMemorySize;
char* VideoMemory;
char* VideoMemoryBuffer;
int numstars = 1000;
int PER = 256;

typedef struct {
	double x, y, z;
	int dx, dy;
} stardata;

int main()
{
	int n, running=1;
	double x, y, z, rx, ry, rz, xoffset=0, yoffset=0, zoffset=0;
	double rads = 360 / (2 * M_PI);
	double sind1, cosd1, sind2, cosd2;
	stardata star[numstars];
	float a1=0, a2=0;
	unsigned char tchar;

	VideoMemory = (char*)b_system_config(20, 0);
	if (VideoMemory == 0)
	{
		printf("Video mode is required for this program.\n");
		return 1;
	}
	VideoX = b_system_config(21, 0);
	VideoY = b_system_config(22, 0);
	VideoBPP = b_system_config(23, 0);

	VideoMemorySize = VideoX * VideoY * (VideoBPP / 4);

	VideoMemoryBuffer = (char*)malloc(VideoMemorySize);

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

	while(running==1)
	{
		tchar = b_input_key();

		if (tchar == 'q')
			running = 0;
		else if (tchar = '-')
			zoffset -= 1000;
		else if (tchar = '=')
			zoffset += 1000;

		sind1 = sin(a1/rads);
		cosd1 = cos(a1/rads);
		sind2 = sin(a2/rads);
		cosd2 = cos(a2/rads);

		for (n=0; n<numstars; n++)
		{
			x = star[n].x + xoffset;
			y = star[n].y + yoffset;
			z = star[n].z + zoffset;

			rx = (x * cosd1) - (z * sind1);
			rz = (x * sind1) + (z * cosd1);
			ry = (y * cosd2) - (rz * sind2);
			rz = (y * sind2) + (rz * cosd2);

			star[n].dx = (VideoX / 2) + ((PER * rx) / rz);
			star[n].dy = (VideoY / 2) + ((PER * ry) / rz);
		}
		a1+=0.01;
		a2+=0.00001;

		// Clear the Video buffer
		memset(VideoMemoryBuffer, 0x00, VideoMemorySize);

		// Draw the scene
		for (n=0; n<numstars; n++)
		{
			put_pixel(star[n].dx, star[n].dy, 255, 255, 255);
		}

		// Write the Video buffer to the screen
		memcpy(VideoMemory, VideoMemoryBuffer, VideoMemorySize);
	}

	clear_screen();
}

void clear_screen()
{
	int bytes = VideoX * VideoY;

	if (VideoBPP == 24)
		bytes = bytes * 3;
	else if (VideoBPP == 32)
		bytes = bytes * 4;

	memset(VideoMemory, 0x00, bytes);
}

void put_pixel(unsigned int x, unsigned int y, unsigned char red, unsigned char green, unsigned char blue)
{
	int offset = 0;
	if (x >= 0 && x < VideoX && y >= 0 && y < VideoY) // Sanity check
	{
		offset = y * VideoX + x;
		if (VideoBPP == 24)
		{
			offset = offset * 3;
			VideoMemoryBuffer[offset] = blue;
			VideoMemoryBuffer[offset+1] = green;
			VideoMemoryBuffer[offset+2] = red;
		}
		else if (VideoBPP == 32)
		{
			offset = offset * 4;
			VideoMemoryBuffer[offset] = 0x00;
			VideoMemoryBuffer[offset+1] = blue;
			VideoMemoryBuffer[offset+2] = green;
			VideoMemoryBuffer[offset+3] = red;
		}
	}
}
