# escape=`
#Escape character directive

#Purpose: To help develop stuff in a containerized environment, with all the necessary tools and packages pre-installed. Make it portable, and run anywhere, amd64 or arm64.

#Base Image
FROM debian:trixie-20240904

ARG username=millify
ARG usergroup=milly_group

ARG userfolder=/usr/${username}

# Create usr folder
RUN mkdir -p ${userfolder}

WORKDIR ${userfolder}

#Create group
RUN groupadd -r ${usergroup}

#Create user with its group
RUN useradd -r -d ${userfolder} -g ${usergroup} ${username}


# Chown all the files to the user.
RUN chown -R ${username}:${usergroup} ${userfolder}

#Change Root password
RUN echo 'toor' | passwd --stdin root 

#Switch to user
USER ${username}


#Update and Upgrade
USER root
RUN <<EOF
apt-get update -y
apt-get upgrade -y
EOF
USER ${username}

## Common Packages
USER root
RUN apt-get install -y dirmngr gnupg software-properties-common curl gcc build-essential &&` 
    apt-get clean
USER ${username}

USER root
## Python, 3.12
RUN apt-get install -y python3.12 &&` 
    apt-get clean
##
USER ${username}




## Node 
ENV NODE_VERSION=22.9.0 
ENV NVM_DIR=/usr/${username}/local/nvm
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
USER root
RUN apt-get install -y clang gdb llvm &&`
    apt-get clean
USER ${username}
##


#Update and Upgrade
USER root
RUN <<EOF
apt-get update -y
apt-get upgrade -y
apt-get clean
EOF
USER ${username}


# Chown all the files to the user again
RUN chown -R ${username}:${usergroup} ${userfolder}

EXPOSE 3005

CMD [ "bash" ]

