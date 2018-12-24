
default:	build

clean:
	rm -rf Makefile objs

build:
	$(MAKE) -f objs/Makefile
	$(MAKE) -f objs/Makefile manpage

install:
	$(MAKE) -f objs/Makefile install

upgrade:
	build/sbin/nginx -t

	kill -USR2 `cat build/logs/nginx.pid`
	sleep 1
	test -f build/logs/nginx.pid.oldbin

	kill -QUIT `cat build/logs/nginx.pid.oldbin`
