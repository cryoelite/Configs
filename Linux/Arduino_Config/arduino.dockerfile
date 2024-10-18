# escape=`
#Escape character directive

#Base Image
FROM debian:trixie-20240904

ARG username=root
ARG C_PORT
ARG userfolder=/root/


#Change Root password
RUN echo 'toor' | passwd --stdin root


#Update and Upgrade
RUN <<EOF
apt-get update -y
apt-get upgrade -y
apt-get clean
EOF

## Common Packages
RUN apt-get install -y dirmngr gnupg software-properties-common curl gcc build-essential p7zip-full nano vim usbutils &&` 
    apt-get clean

## Python, 3.12
RUN apt-get install -y python3.12 &&` 
    apt-get clean
##


## Rust
RUN curl --proto '=https' --tlsv1.3 https://sh.rustup.rs -sSf | sh -s -- -y

ENV CARGO_HOME="${userfolder}/.cargo"
ENV PATH="$CARGO_HOME/bin:$PATH"
##

##C++
RUN apt-get install -y clang gdb llvm &&`
    apt-get clean
##


#Update and Upgrade
RUN <<EOF
apt-get update -y
apt-get upgrade -y
apt-get clean
EOF

EXPOSE ${C_PORT}
USER ${username}

CMD [ "bash" ]

