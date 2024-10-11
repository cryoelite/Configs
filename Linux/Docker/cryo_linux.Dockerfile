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

#Update and Upgrade
RUN <<EOF
apt-get update -y
apt-get upgrade -y
EOF


## Common Packages
RUN apt-get install -y dirmngr gnupg software-properties-common curl gcc &&` 
    apt-get clean

## Python, 3.12
RUN apt-get install -y python3.12 &&` 
    apt-get clean
##


#Switch to user
USER ${username}

## Node 
# Install nodejs, 22.9.0 
ENV NVM_DIR="/home/${username}/.nvm"

RUN curl -o ${NVM_DIR}/nvm.sh https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.1/install.sh 
RUN . "${NVM_DIR}/nvm.sh" && `
nvm install v22.9.0

ENV NVM_DIR="/home/${username}/.nvm"

ENV PATH="$NVM_DIR/versions/node/v22.9.0/bin:$PATH"

#'node' and 'npm' installed
##


## Rust
RUN curl --proto '=https' --tlsv1.3 https://sh.rustup.rs -sSf | sh -s -- -y

ENV CARGO_HOME="$HOME/.cargo"
ENV PATH="$CARGO_HOME/bin:$PATH"
##

USER root

#Update and Upgrade
RUN <<EOF
apt-get update -y
apt-get upgrade -y
apt-get clean
EOF

USER ${username}

EXPOSE 3005

CMD [ "bash" ]

