# escape=`
#Escape character directive

#Base Image
FROM debian:trixie-20240904

ARG username=root
ARG C_PORT
ARG GIT_TOKEN
ARG GIT_USERNAME
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
RUN apt-get install -y dirmngr gnupg software-properties-common curl gcc build-essential p7zip-full nano vim usbutils git libreoffice &&` 
    apt-get clean
##

##Setup git
RUN curl --request GET `
    --url "https://api.github.com/${GIT_USERNAME}" `
    --header "Authorization: Bearer ${GIT_TOKEN}" `
    --header "X-GitHub-Api-Version: 2022-11-28"
##


## Python
RUN apt-get install -y python3 python3-venv &&` 
    apt-get clean
##


## Rust
RUN curl --proto '=https' --tlsv1.3 https://sh.rustup.rs -sSf | sh -s -- -y

ENV CARGO_HOME="${userfolder}/.cargo"
ENV PATH="$CARGO_HOME/bin:$PATH"
##

##C++
RUN apt-get install -y clang clangd gdb llvm &&`
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

