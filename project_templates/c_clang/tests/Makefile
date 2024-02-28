CC=clang
CFLAGS=-ggdb

OBJECTS_TO_LINK=

all:
	$(CC) $(CFLAGS) -c unity.c
	$(CC) $(CFLAGS) -o tests test_main.c unity.o $(OBJECTS_TO_LINK)

clean:
	rm -f *.o tests
