netscripts.tar.xz: ns.sh LICENSE netscripts.timer netscripts.service
	tar cvJf $@ $^

.PHONY: clean
clean:
	rm netscripts.tar.xz
