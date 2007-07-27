
# Awkbot makefile, mostly just to bootstrap the test suite, but will also run
# cpp to perminantly generate awkbot and awkpaste..

awkbot:
	cpp -I /usr/share/awk -I lib lib/awkbot-boot.awk 2> /dev/null > bootstrap
	cpp -I /usr/share/awk/ -I lib lib/awkbot.awk 2> /dev/null > bootstrap

awkpaste:
	cpp -I /usr/share/awk -I lib lib/awkpaste.awk 2> /dev/null > awkpaste

test:
	./bin/teststrap
