# Makefile
# vim:ft=make

all: install

install:
	# TODO Install docker
	# TODO Install consul
	# TODO Install go
	# TODO Install Ansible
	go get -u github.com/flynn/gitreceived
	sudo cp auth.sh batcave.sh /usr/local/bin
	[ -d /etc/service/sshd ] && rm -r /etc/service/sshd
	cp build/batcave_id_rsa ~/.ssh
	# Install https://github.com/stedolan/jq
	wget http://stedolan.github.io/jq/download/linux64/jq
	chmod 755 jq && sudo mv jq /usr/local/bin

ssh:
	eval `ssh-agent -s`
	@echo "waiting ssh-agent to be started..."
	sleep 5
	ssh-add ~/.ssh/batcave_id_rsa

.PHONY: install ssh
