# Use Ubuntu as the base image
FROM rust:1.80 as builder

# Avoid prompts from apt
# ENV DEBIAN_FRONTEND=noninteractive

# Set the working directory in the container
WORKDIR /usr/src/app

# Install system dependencies including OpenSSL dev libraries
RUN apt-get update && apt-get install -y \
    build-essential \
    curl \
    git \
    libssl-dev \
    pkg-config \
    && rm -rf /var/lib/apt/lists/*

# Set OpenSSL directory and other environment variables
ENV OPENSSL_DIR=/usr/lib/ssl \
    OPENSSL_LIB_DIR=/usr/lib/x86_64-linux-gnu \
    OPENSSL_INCLUDE_DIR=/usr/include/openssl

# Install Foundry
RUN curl -L https://foundry.paradigm.xyz | bash
ENV PATH="/root/.foundry/bin:${PATH}"
# Ensure Foundry is installed correctly
RUN foundryup

# Verify Foundry installation
RUN forge --version

# Install cargo-risczero
RUN cargo install cargo-binstall
RUN cargo binstall cargo-risczero -y
RUN cargo risczero install

# Copy the Cargo.toml and Cargo.lock files
COPY Cargo.toml Cargo.lock ./

# Copy the entire project
COPY . .

# Build the application
RUN cargo build --release

# Start a new stage for a smaller final image
FROM debian:buster-slim

# Install necessary runtime libraries
RUN apt-get update && apt-get install -y \
    libssl1.1 \
    && rm -rf /var/lib/apt/lists/*

# Copy the binary from the builder stage
COPY --from=builder /usr/src/app/target/release/server /usr/local/bin/server

# Set the startup command
CMD ["server"]