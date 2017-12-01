TARGET = test_driver_cmd
CC=gcc
CFLAGS = -Werror -Wall -Wpedantic -Wextra -std=c11 -g
SRC = test_driver_cmd.c driver_cmd.c
OBJ = $(SRC:.c=.o)

build: $(TARGET)

lib/%.o: $(SRC)
	$(CC) $(CFLAGS) -c $< -o $@

$(TARGET): $(OBJ)
	$(CC) $(OBJ) -o $@

lint:
	clang-format -i *.c *.h
	git status --porcelain | grep -e "^ M" && exit 1 || exit 0

test: $(TARGET)
	./$(TARGET)

host:
	
.PHONY: clean

clean:
	rm -rf *.o
	rm -rf $(TARGET)
