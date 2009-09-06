all: test

test: test.a51
	asem test.a51

install: test
	./aduc8xx.pl --port /dev/ttyUSB0 --detect --echip --program test.hex

clean:
	rm -f *.hex *.lst

push:
	git push git@github.com:nblythe/TagBot.git master

