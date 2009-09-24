AS=asem

all: main

main: main.a51
	$(AS) main.a51

install: main
	./aduc8xx.pl --port /dev/ttyUSB0 --detect --echip --program main.hex

clean:
	rm -f *.hex *.lst

push:
	git push git@github.com:nblythe/TagBot.git master

