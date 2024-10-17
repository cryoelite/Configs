# escape=`
#Escape character directive

#Purpose: To help develop stuff in a containerized environment, with all the necessary tools and packages pre-installed. Make it portable, and run anywhere, amd64 or arm64.

#Base Image
FROM debian:trixie-20240904

#ARG username=millify
ARG username=root
#ARG usergroup=milly_group
#ARG usergroup=root 
##Security flaw but f that, theres no sudo, apt-get doesn't work with non-root users (Permission denied) and more issues. Root for now. TODO: Investigate, improve understanding or fix.
#ARG userpass=toor
#ARG userfolder=/home/${username}
ARG userfolder=/root/

##Update and Upgrade
#RUN <<EOF
#apt-get update -y
#apt-get upgrade -y
#apt-get clean
#EOF
#
#
#
###Create group, system group, -f means force, if group exists, does nothing, else creates it.
#RUN groupadd -r -f ${usergroup}  
#
#RUN useradd -r -m -d ${userfolder} -g ${usergroup} -s /bin/bash ${username}
#
##Add user to root
#RUN <<EOF
#apt-get update -y
#apt-get install -y sudo && echo "${username} ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers
#EOF
#
## Chown all the files to the user.
#RUN chown -R ${username}:${usergroup} ${userfolder}
#
###Change Root password
RUN echo 'toor' | passwd --stdin root
#RUN echo ${userpass} | passwd --stdin ${username} 
#
#WORKDIR ${userfolder}
#USER ${username}
## Doesn't work, still permission denied with apt-get

#Update and Upgrade
RUN <<EOF
apt-get update -y
apt-get upgrade -y
apt-get clean
EOF


## Common Packages
RUN apt-get install -y dirmngr gnupg software-properties-common curl gcc build-essential p7zip-full nano vi&&` 
    apt-get clean

## Python, 3.12
RUN apt-get install -y python3.12 &&` 
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
RUN apt-get install -y clang gdb llvm &&`
    apt-get clean
##


#Update and Upgrade
RUN <<EOF
apt-get update -y
apt-get upgrade -y
apt-get clean
EOF


# Chown all the files to the user again
##RUN chown -R ${username}:${usergroup} ${userfolder}

EXPOSE 3005
USER ${username}

CMD [ "bash" ]

