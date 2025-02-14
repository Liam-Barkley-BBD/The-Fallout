# From Adrian Hawkins -- DISB Collegue

FROM ubuntu:latest
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y \
   curl \
   unzip \
   vim \
   neovim \
   apt-transport-https \
   lsb-release \
   gnupg \
   software-properties-common \
   ca-certificates \
   git \
   && rm -rf /var/lib/apt/lists/*

RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" \
   && unzip awscliv2.zip \
   && ./aws/install \
   && rm -rf aws awscliv2.zip

RUN curl -fsSL https://apt.releases.hashicorp.com/gpg | apt-key add - \
   && apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main" \
   && apt-get update && apt-get install -y terraform \
   && rm -rf /var/lib/apt/lists/*

WORKDIR /workspace
#COPY ./Terraform /workspace
ENTRYPOINT ["top", "-b"]