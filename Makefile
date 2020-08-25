netscripts.tar.xz: ns.sh LICENSE
	tar cvJf $@ ns.sh LICENSE

.PHONY: clean
clean:
	rm netscripts.tar.xz
