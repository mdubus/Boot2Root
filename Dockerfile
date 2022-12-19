FROM	kalilinux/kali-linux-docker

RUN		apt update -y && \
		apt upgrade -y && \
		apt install -y dirb nmap ftp ssh vim gcc squashfs-tools

