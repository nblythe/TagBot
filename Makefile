AS=asem

all: test pwm

test: test.a51
	$(AS) test.a51

pwm: pwm.a51
	$(AS) pwm.a51

install: pwm
	./aduc8xx.pl --port /dev/ttyUSB0 --detect --echip --program pwm.hex

clean:
	rm -f *.hex *.lst

push:
	git push git@github.com:nblythe/TagBot.git master

