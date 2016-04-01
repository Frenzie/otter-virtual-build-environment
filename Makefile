.PHONY: all clean jessie32 jessie64 up packer

all: clean build up 

jessie32 jessie64:
	@cd debian && \
	packer build debian-$@.json && \
	vagrant box add --name $@ --force $@.box && \
	vagrant up

up:
	vagrant destroy -f && vagrant box remove vagrant_machine && vagrant up || vagrant box remove vagrant_machine && vagrant up || vagrant up

clean:
	rm ./packer-debian-stable.box && rm -rf ./packer_cache && vagrant destroy -f && vagrant box remove vagrant_machine || true

packer:
	@if [ ! -w /usr/local/bin ]; then \
		echo "\nInsufficient permission to write to /usr/local/bin. Try su or sudo.\n"; \
		false; \
	fi
	@cd /usr/local/bin && \
	wget --continue --output-document=/tmp/packer.zip \
		https://releases.hashicorp.com/packer/0.10.0/packer_0.10.0_linux_amd64.zip && \
	unzip /tmp/packer.zip
