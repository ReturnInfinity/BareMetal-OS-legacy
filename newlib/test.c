#include <stdio.h>

char tempstring[32];

int main()
{
	printf("NewLib Test Application\n=======================\n");
	printf("%s %d\n", "Output:", 1234);
	printf("Enter some text: ");
	fgets(tempstring, 32, stdin);			// Get up to 32 chars from the keyboard
	printf("You entered: '%s'", tempstring);
}