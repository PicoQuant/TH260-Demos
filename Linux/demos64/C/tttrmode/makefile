#
# Makefile for demo with th260lib.so


# Paths

LBITS := $(shell getconf LONG_BIT)
ifeq ($(LBITS),64)
   # 64 bit
   LPATH = /usr/local/lib64/th260/
else
   # 32 bit
   LPATH = /usr/local/lib/th260/
endif

# Flags

CC = gcc

WARN = -Wall -Wno-format
COPTS = -g -O

CFLAGS = $(WARN) $(COPTS)

# Rules

%.o: %.c
	$(CC) -c $(CFLAGS) -I$(LPATH) -o $@ $<

# Variables

BINS = tttrmode
SRCS = tttrmode.c
OBJS = $(SRCS:%.c=%.o)

# Main target

all: $(BINS)

# Dependencies

tttrmode: tttrmode.o
	$(CC) $(OBJS) $(LPATH)th260lib.so -o $@

# Misc

clean:
	rm -f *.o *~ ~* *.bck core
	rm -f $(BINS)

