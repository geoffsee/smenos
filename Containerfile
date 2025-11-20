FROM debian:trixie

# --- System deps ---
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    ca-certificates \
    build-essential \
    musl-tools \
    musl-dev \
    libssl-dev \
    pkg-config \
    libasound2-dev \
    clang \
    llvm \
    git \
    zlib1g-dev \
    gcc \
    g++ \
    make \
    cmake \
    maven \
    libz-dev \
    libjpeg62-turbo-dev \
    libpng-dev \
    libtiff-dev \
    libmagic-dev \
 && rm -rf /var/lib/apt/lists/*


WORKDIR /opt/graalvm
RUN wget https://download.oracle.com/graalvm/25/latest/graalvm-jdk-25_linux-aarch64_bin.tar.gz
RUN tar -xzf graalvm-jdk-25_linux-aarch64.tar.gz

ENV JAVA_HOME=/opt/graalvm/graalvm-jdk-25_linux-aarch64/
ENV PATH=$JAVA_HOME/bin:$PATH

WORKDIR /opt
RUN apt-get install git
RUN git clone https://github.com/apache/tika.git

ARG TIKA_VERSION=3.2.3

WORKDIR /opt/tika
RUN mvn install -f pom.xml

# Install the built native library into /usr/local/lib
RUN cp /opt/tika-native/build/libtika_native.so /usr/local/lib/ && \
    ldconfig

# Optional: create directory for Java to load JNI libs easily
ENV LD_LIBRARY_PATH="/usr/local/lib:${LD_LIBRARY_PATH}"

WORKDIR /
# --- Install Rust toolchain ---
RUN curl https://sh.rustup.rs -sSf | sh -s -- -y
ENV PATH="/root/.cargo/bin:${PATH}"

# --- Install DuckDB CLI ---
RUN curl https://install.duckdb.org | sh
ENV PATH="${PATH}:/root/.duckdb/cli/latest"

# --- Install cargo-binstall ---
RUN cargo install cargo-binstall --locked

# --- Install required tools ---
RUN cargo binstall -y spec-ai muxox && \
    find /root/.cargo -name "libtika_native.so" -exec cp {} /usr/local/lib/ \; && \
    ldconfig

# --- Set library path ---
ENV LD_LIBRARY_PATH="/usr/local/lib:/usr/lib:${LD_LIBRARY_PATH}"

# --- App files ---
WORKDIR /app
COPY . /app

# --- Entrypoint ---
ENTRYPOINT ["muxox"]
