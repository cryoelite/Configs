# escape=`

#Purpose: To help develop stuff in a containerized environment, with all the necessary tools and packages pre-installed. Make it portable, and run anywhere, amd64 or arm64.

FROM debian:trixie-20240904

ARG username=root
ARG GIT_TOKEN
ARG GIT_USERNAME
ARG C_PORT
ARG userfolder=/root/

RUN echo 'toor' | passwd --stdin root

#Update and upgrade
RUN <<EOF
apt-get update -y &&
apt-get upgrade -y &&
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


## Node 
ENV NODE_VERSION=22.9.0 
ENV NVM_DIR=${userfolder}/local/nvm
RUN mkdir -p ${NVM_DIR}

RUN curl https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.1/install.sh | bash &&`
    . $NVM_DIR/nvm.sh &&`
    nvm install $NODE_VERSION &&`
    nvm alias default $NODE_VERSION &&`
    nvm use default 
#or use brew 

ENV NODE_PATH=$NVM_DIR/v$NODE_VERSION/lib/node_modules
ENV PATH=$NVM_DIR/versions/node/v$NODE_VERSION/bin:$PATH
ENV PATH=$NVM_DIR:$PATH
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
apt-get update -y &&
apt-get upgrade -y &&
apt-get clean
EOF

EXPOSE ${C_PORT}
USER ${username}

CMD [ "bash" ]

