AS=asem

all: test pwm states

test: test.a51
	$(AS) test.a51

pwm: pwm.a51
	$(AS) pwm.a51

states: states.a51
	$(AS) states.a51

install: states
	./aduc8xx.pl --port /dev/ttyUSB0 --detect --echip --program states.hex

clean:
	rm -f *.hex *.lst

push:
	git push git@github.com:nblythe/TagBot.git master

