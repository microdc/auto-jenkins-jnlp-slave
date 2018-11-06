FROM openjdk:8

# those are allowed to be changed at build time`
ARG user=jenkins
ARG group=jenkins
ARG uid=1000
ARG gid=1000

RUN apt-get update -y

RUN apt-get install -y  curl dumb-init git openssh-client bash jq gettext

#Install Docker
RUN apt-get install -y login docker

#Install kubectl
RUN curl -L -o /usr/bin/kubectl https://storage.googleapis.com/kubernetes-release/release/v1.10.2/bin/linux/amd64/kubectl && chmod +x /usr/bin/kubectl

#Install aws cli and azure cli
RUN apt-get install -y docker groff python python-pip gettext procps xz-utils && \
    apt-get install -y gcc libffi-dev libssl-dev python-dev python3-dev make && \
    #pip install --upgrade pip==18.0 && \
    pip install awscli s3cmd azure-cli yamllint

# Install shellcheck for validating shell scripts in CI pipelines
RUN curl -o /tmp/shellcheck.tar.xz https://shellcheck.storage.googleapis.com/shellcheck-v0.5.0.linux.x86_64.tar.xz && \
    cd /tmp && tar xJf shellcheck.tar.xz && cd shellcheck-* && \
    mv shellcheck /usr/local/bin && rm -r /tmp/shellcheck*

ENV JENKINS_HOME=/var/jenkins_home \
    JENKINS_USER=${user}

RUN  groupadd -g ${gid} ${group} && \
     useradd -d "$JENKINS_HOME" -u ${uid} -g ${gid} -m -s /bin/bash ${user} && \
     sed -i '/^Host \*/a \ \ \ \ ServerAliveInterval 30' /etc/ssh/ssh_config && \
     sed -i '/^Host \*/a \ \ \ \ StrictHostKeyChecking no' /etc/ssh/ssh_config

# Jenkins home directory is a volume, so configuration and build history
# can be persisted and survive image upgrades
VOLUME $JENKINS_HOME

COPY jenkins-slave /usr/local/bin/jenkins-slave
RUN chmod +x /usr/local/bin/jenkins-slave

ENTRYPOINT ["/usr/bin/dumb-init", "--"]
CMD ["/usr/local/bin/jenkins-slave"]
