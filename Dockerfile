ARG TEST_BUILD=0
FROM python:3.11-slim-bullseye AS jesse_basic_env
ENV PYTHONUNBUFFERED=1

RUN apt-get update \
    && apt-get -y install git build-essential libssl-dev \
    && apt-get clean \
    && pip install --upgrade pip

RUN pip3 install Cython numpy

# Prepare environment
RUN mkdir /jesse-docker
WORKDIR /jesse-docker

# Install TA-lib
COPY docker_build_helpers/* /tmp/

ARG TARGETARCH
ENV TARGETARCH=${TARGETARCH}

RUN case "$TARGETARCH" in \
      "amd64") BUILD_TRIPLET=x86_64-unknown-linux-gnu ;; \
      "arm64") BUILD_TRIPLET=aarch64-unknown-linux-gnu ;; \
      *) echo "Unsupported architecture: $TARGETARCH" && exit 1 ;; \
    esac && \
    echo "Detected architecture: $TARGETARCH, Build triplet: $BUILD_TRIPLET" && \
    cd /tmp && /tmp/install_ta-lib.sh /usr/local ${BUILD_TRIPLET} && rm -r /tmp/*ta-lib*

# Install dependencies
COPY requirements.txt /jesse-docker
RUN pip3 install -r requirements.txt

# Build
COPY . /jesse-docker
RUN pip3 install -e .

FROM jesse_basic_env AS jesse_with_test_0
WORKDIR /home

FROM jesse_basic_env AS jesse_with_test_1
RUN pip3 install codecov pytest-cov
ENTRYPOINT pytest --cov=./ # && codecov

FROM jesse_with_test_${TEST_BUILD} AS jesse_final
