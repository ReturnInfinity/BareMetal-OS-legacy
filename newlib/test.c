#include <stdio.h>
#include <time.h>

char tempstring[32];

int main(int argc, char *argv[])
{
	struct tm *local;
	time_t t;
	int i=0;

	printf("NewLib Test Application\n=======================\n");

	// Test argument parsing
	printf("argc: %d\n", argc);
	for (i=0; i < argc; i++)
		printf("argv[%d]: %s\n", i, argv[i]);
	printf("\n");

	// Test time
	t = time(NULL);
	local = localtime(&t);
	printf("Local time and date: %s\n", asctime(local));

	// Test IO
	printf("%s %d\n", "Output:", 1234);
	printf("Enter some text: ");
	fgets(tempstring, 32, stdin);			// Get up to 32 chars from the keyboard
	printf("You entered: '%s'", tempstring);
}
