
openssll.so:
	gcc -g -O0 -Wall -fPIC --shared -Wl,-E openssll.c -llua -lssl -lcrypto  -o openssll.so
	rm ../../luaclib/openssll.so
	cp openssll.so ../../luaclib/openssll.so

