FROM 113355358853.dkr.ecr.eu-west-1.amazonaws.com/example/1/2/3/jenkins-worker:latest


USER root

ENV http_proxy 'http://proxy.local:8080'
ENV https_proxy 'http://proxy.local:8080'
ENV no_proxy 'localhost, 127.0.0.1, 169.254.169.254, .svc.cluster.local'

RUN apk update --no-cache && \
    apk upgrade --no-cache && \
    apk add --no-cache gettext coreutils


#######################################################################
# Installing kubectl
#######################################################################

ARG KUBECTL_VERSION=1.16.9
ARG KUBECTL_URL=https://storage.googleapis.com/kubernetes-release/release/v${KUBECTL_VERSION}/bin/linux/amd64/kubectl
ARG KUBECTL_SHA256=0f3a6618a2e7402b11a1d9b9ffeff3ba0c6765dc361815413ce7441799aecf96

WORKDIR /tmp
RUN curl -fsSL ${KUBECTL_URL} -o /usr/local/bin/kubectl && \
    echo "${KUBECTL_SHA256}  /usr/local/bin/kubectl" | sha256sum -c - && \
    chmod +x /usr/local/bin/kubectl

#######################################################################
# Installing helm
#######################################################################

ARG HELM_VERSION=3.8.0
ARG HELM_ARCHITECTURE=linux-amd64
ARG HELM_URL=https://get.helm.sh/helm-v${HELM_VERSION}-${HELM_ARCHITECTURE}.tar.gz
ARG HELM_SHA256_URL=https://get.helm.sh/helm-v${HELM_VERSION}-${HELM_ARCHITECTURE}.tar.gz.sha256
ARG HELMFILE_VERSION=0.138.7
ARG HELM_DIFF_VERSION=3.1.3

WORKDIR /tmp
RUN curl -fsSL ${HELM_URL} -o helm-${HELM_ARCHITECTURE}.tar.gz && \
    echo "$(curl -fsSL ${HELM_SHA256_URL})  helm-${HELM_ARCHITECTURE}.tar.gz" | sha256sum -c - && \
    tar -xvzf helm-${HELM_ARCHITECTURE}.tar.gz ${HELM_ARCHITECTURE}/helm && \
    mv ${HELM_ARCHITECTURE}/helm /usr/local/bin/ && \
    rm -f helm-${HELM_ARCHITECTURE}.tar.gz
RUN ln -s /usr/local/bin/helm /usr/local/bin/helm3
WORKDIR /

# Install Helmfile
RUN curl -L -o helmfile_linux_amd64 https://github.com/roboll/helmfile/releases/download/v${HELMFILE_VERSION}/helmfile_linux_amd64 && \
    mv helmfile_linux_amd64 /usr/bin/helmfile && \
    chmod +x /usr/bin/helmfile && \
    rm -rf helmfile_linux_amd64

RUN helm plugin install https://github.com/databus23/helm-diff --version ${HELM_DIFF_VERSION}

#######################################################################
# Install Trivy
#######################################################################

RUN curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh -s -- -b /usr/local/bin v0.18.3

#######################################################################
# Install Dive
#######################################################################

ARG DIVE_VERSION=0.10.0
ARG DIVE_URL=https://github.com/wagoodman/dive/releases/download/v${DIVE_VERSION}/dive_${DIVE_VERSION}_linux_amd64.tar.gz
ARG DIVE_SHA_256="9541997876d4985de66d0fa5924dac72258a3094ef7d3f6ef5fa5dcf6f6a47ad"

RUN curl -fsSL ${DIVE_URL} -o dive-${DIVE_VERSION}.tar.gz && \
    echo ${DIVE_SHA_256} dive-${DIVE_VERSION}.tar.gz | sha256sum -c - && \
    tar -xvzf dive-${DIVE_VERSION}.tar.gz dive && \
    mv dive /usr/local/bin/ && \
    rm -f dive-${DIVE_VERSION}.tar.gz

#######################################################################
# Install Kubernetes Python Client
#######################################################################

ARG K8S_CLIENT_VERSION=17.17.0
RUN pip install kubernetes==${K8S_CLIENT_VERSION}

#######################################################################
# Install Joblib Python Library
#######################################################################

ARG JOBLIB_VERSION=1.0.1
RUN pip install joblib==${JOBLIB_VERSION}

#######################################################################
# Copy in data directory and set permissions
#######################################################################

COPY data /
RUN setfacl --restore=permissions.facl && \
    rm -f permissions.facl

ENTRYPOINT /entrypoint.sh
