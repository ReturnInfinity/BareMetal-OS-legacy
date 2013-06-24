#include <stdio.h>
#include <time.h>

char tempstring[32];

int main()
{
	struct tm *local;
	time_t t;

	printf("NewLib Test Application\n=======================\n");
	t = time(NULL);
	local = localtime(&t);
	printf("Local time and date: %s\n", asctime(local));
	printf("%s %d\n", "Output:", 1234);
	printf("Enter some text: ");
	fgets(tempstring, 32, stdin);			// Get up to 32 chars from the keyboard
	printf("You entered: '%s'", tempstring);
}
