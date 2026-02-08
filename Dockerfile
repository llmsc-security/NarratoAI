# -------------------------------------------------
#  Builder stage – compile and install Python deps
# -------------------------------------------------
FROM python:3.12-slim-bookworm AS builder

# Prevent interactive prompts during apt operations
ARG DEBIAN_FRONTEND=noninteractive

# Working directory for the build
WORKDIR /build

# Install build‑time system packages (including SSL headers and certs for pip)
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        build-essential \
        git \
        pkg-config \
        ca-certificates \
        libssl-dev \
        libffi-dev && \
    rm -rf /var/lib/apt/lists/*

# Upgrade pip/setuptools/wheel and create a virtual‑env
RUN python -m pip install --upgrade pip setuptools wheel && \
    python -m venv /opt/venv

# Make the venv the default Python environment for the rest of the stage
ENV VIRTUAL_ENV=/opt/venv
ENV PATH="${VIRTUAL_ENV}/bin:${PATH}"
ENV PIP_NO_CACHE_DIR=1

# Install runtime Python packages
COPY requirements.txt .
# Increase pip timeout – useful on slower mirrors
RUN pip install --default-timeout=300 --no-cache-dir -r requirements.txt

# -------------------------------------------------
#  Runtime stage – lightweight image with app code
# -------------------------------------------------
FROM python:3.12-slim-bookworm

ARG DEBIAN_FRONTEND=noninteractive

# Application work directory
WORKDIR /narratoai

# Copy the pre‑built virtual environment from the builder
COPY --from=builder /opt/venv /opt/venv

# Install only the runtime system packages
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        imagemagick \
        ffmpeg \
        wget \
        curl \
        ca-certificates \
        dos2unix && \
    # Relax ImageMagick policy that blocks reading/writing of files (needed by some apps)
    sed -i 's/<policy domain="path" rights="none" pattern="@\*"/<policy domain="path" rights="read|write" pattern="@\*"/' \
        /etc/ImageMagick-6/policy.xml || true && \
    # Create a non‑root user and give it ownership of the app directory
    groupadd -r narratoai && \
    useradd -r -g narratoai -d /narratoai -s /bin/bash narratoai && \
    rm -rf /var/lib/apt/lists/*

# Environment variables – make the venv the default Python interpreter
ENV VIRTUAL_ENV=/opt/venv
ENV PATH="${VIRTUAL_ENV}/bin:${PATH}" \
    PYTHONPATH="/narratoai" \
    PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONIOENCODING=utf-8 \
    LANG=C.UTF-8 \
    LC_ALL=C.UTF-8

# -----------------------------------------------------------------
#  Entrypoint & application files
# -----------------------------------------------------------------
# Copy the entrypoint script, fix line endings and make it executable
COPY docker-entrypoint.sh /usr/local/bin/
RUN dos2unix /usr/local/bin/docker-entrypoint.sh && \
    chmod +x /usr/local/bin/docker-entrypoint.sh

# Copy the application source (respect .dockerignore) and set correct ownership
COPY --chown=narratoai:narratoai . .

# Create required directories, provide a default config if missing and set permissions
RUN mkdir -p storage/temp storage/tasks storage/json \
            storage/narration_scripts storage/drama_analysis && \
    if [ ! -f config.toml ]; then cp config.example.toml config.toml; fi && \
    chown -R narratoai:narratoai /narratoai && \
    chmod -R 755 /narratoai

# Switch to the non‑root user for running the app
USER narratoai

# -------------------------------------------------
#  Container metadata
# -------------------------------------------------
EXPOSE 8501

# Health‑check – Streamlit’s built‑in endpoint (longer start‑period for slower startups)
HEALTHCHECK --interval=30s --timeout=10s --start-period=120s --retries=3 \

*** Begin Patch
*** Update File: Dockerfile
 FROM python:3.12-slim-bookworm
 RUN apt-get update && \
     apt-get install -y --no-install-recommends \
         imagemagick \
         ffmpeg \
         wget \
         curl \
         ca-certificates \
       dos2unix && \
       dos2unix \
       # Runtime equivalents of the build‑time libs needed by compiled wheels
       libssl3 \
       libffi8 \
       # Common runtime deps for scientific / data‑processing wheels
       libgomp1 && \
     # Relax ImageMagick policy that blocks reading/writing of files (needed by some apps)
   rm -rf /var/lib/apt/lists/*
   rm -rf /var/lib/apt/lists/*
*** End Patch

*** Begin Patch
*** Update File: Dockerfile
-# -------------------------------------------------
-#  Runtime stage – lightweight image with app code
-# -------------------------------------------------
-FROM python:3.12-slim-bookworm
-
-ARG DEBIAN_FRONTEND=noninteractive
-
-# Application work directory
-WORKDIR /narratoai
-
-# Copy the pre‑built virtual environment from the builder
-COPY --from=builder /opt/venv /opt/venv
-
-# Install only the runtime system packages
-RUN apt-get update && \
   apt-get install -y --no-install-recommends \
       imagemagick \
       ffmpeg \
       wget \
       curl \
       ca-certificates \
       dos2unix && \
   # Relax ImageMagick policy that blocks reading/writing of files (needed by some apps)
   sed -i 's/<policy domain="path" rights="none" pattern="@\*"/<policy domain="path" rights="read|write" pattern="@\*"/' \
       /etc/ImageMagick-6/policy.xml || true && \
   # Create a non‑root user and give it ownership of the app directory
   groupadd -r narratoai && \
   useradd -r -g narratoai -d /narratoai -s /bin/bash narratoai && \
   rm -rf /var/lib/apt/lists/*
+# -------------------------------------------------
+#  Runtime stage – lightweight image with app code
+# -------------------------------------------------
+FROM python:3.12-slim-bookworm AS runtime
+
+ARG DEBIAN_FRONTEND=noninteractive
+
+# Application work directory
+WORKDIR /narratoai
+
+# Copy the pre‑built virtual environment from the builder
+COPY --from=builder /opt/venv /opt/venv
+
+# Install only the runtime system packages (including libraries required by compiled wheels)
+RUN apt-get update && \
   apt-get install -y --no-install-recommends \
       imagemagick \
       ffmpeg \
       wget \
       curl \
       ca-certificates \
       dos2unix \
       libssl3 \
       libffi8 \
       libgomp1 && \
   rm -rf /var/lib/apt/lists/* && \
   # Relax ImageMagick policy that blocks reading/writing of files (needed by some apps)
   sed -i 's/<policy domain="path" rights="none" pattern="@\*"/<policy domain="path" rights="read|write" pattern="@\*"/' \
       /etc/ImageMagick-6/policy.xml || true && \
   # Create a non‑root user and give it ownership of the app directory
   groupadd -r narratoai && \
   useradd -r -g narratoai -d /narratoai -s /bin/bash narratoai
-HEALTHCHECK --interval=30s --timeout=10s --start-period=120s --retries=3 \
-
-*** Begin Patch
-*** Update File: Dockerfile
FROM python:3.12-slim-bookworm
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        imagemagick \
        ffmpeg \
        wget \
        curl \
        ca-certificates \
      dos2unix && \
      dos2unix \
      # Runtime equivalents of the build‑time libs needed by compiled wheels
      libssl3 \
      libffi8 \
      # Common runtime deps for scientific / data‑processing wheels
      libgomp1 && \
    # Relax ImageMagick policy that blocks reading/writing of files (needed by some apps)
  rm -rf /var/lib/apt/lists/*
  rm -rf /var/lib/apt/lists/*
-*** End Patch
-

### New Dockerfile (replace the entire current file)
```dockerfile
# -------------------------------------------------
#  Builder stage – compile and install Python deps
# -------------------------------------------------
FROM python:3.12-slim-bookworm AS builder
ARG DEBIAN_FRONTEND=noninteractive
WORKDIR /build

# Install build‑time system packages (compilers, headers, git, etc.)
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        build-essential \
        git \
        pkg-config \
        ca-certificates \
        libssl-dev \
        libffi-dev && \
    rm -rf /var/lib/apt/lists/*

# Create a virtual environment that will be copied to the runtime image
RUN python -m venv /opt/venv && \
    /opt/venv/bin/pip install --upgrade pip setuptools wheel

ENV VIRTUAL_ENV=/opt/venv
ENV PATH="$VIRTUAL_ENV/bin:$PATH"
ENV PIP_NO_CACHE_DIR=1

# Install Python requirements inside the venv
COPY requirements.txt .
RUN pip install --default-timeout=300 -r requirements.txt

# -------------------------------------------------
#  Runtime stage – lightweight image with app code
# -------------------------------------------------
FROM python:3.12-slim-bookworm AS runtime
ARG DEBIAN_FRONTEND=noninteractive
WORKDIR /narratoai

# Copy the pre‑built virtual environment from the builder
COPY --from=builder /opt/venv /opt/venv

# Install only the runtime system packages (including libs needed by wheels)
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        imagemagick \
        ffmpeg \
        wget \
        curl \
        ca-certificates \
        dos2unix \
        libssl3 \
        libffi8 \
        libgomp1 && \
    rm -rf /var/lib/apt/lists/* && \
    # Relax ImageMagick policy that blocks file I/O (required by some apps)
    sed -i 's/<policy domain="path" rights="none" pattern="@\*"/<policy domain="path" rights="read|write" pattern="@\*"/' /etc/ImageMagick-6/policy.xml || true && \
    # Create a non‑root user and give it ownership of the app directory
    groupadd -r narratoai && \
    useradd -r -g narratoai -d /narratoai -s /bin/bash narratoai

# Make the venv the default Python interpreter
ENV VIRTUAL_ENV=/opt/venv
ENV PATH="$VIRTUAL_ENV/bin:$PATH" \
    PYTHONPATH="/narratoai" \
    PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONIOENCODING=utf-8 \
    LANG=C.UTF-8 \
    LC_ALL=C.UTF-8

# -----------------------------------------------------------------
#  Entrypoint & application files
# -----------------------------------------------------------------
COPY docker-entrypoint.sh /usr/local/bin/
RUN dos2unix /usr/local/bin/docker-entrypoint.sh && chmod +x /usr/local/bin/docker-entrypoint.sh

# Copy the application source (respect .dockerignore) and set correct ownership
COPY --chown=narratoai:narratoai . .

# Create required directories, provide a default config if missing and set permissions
RUN mkdir -p storage/temp storage/tasks storage/json \
            storage/narration_scripts storage/drama_analysis && \
    if [ ! -f config.toml ]; then cp config.example.toml config.toml; fi && \
    chown -R narratoai:narratoai /narratoai && \
    chmod -R 755 /narratoai

USER narratoai

# -------------------------------------------------
#  Container metadata
# -------------------------------------------------
EXPOSE 8501

# Health‑check – Streamlit’s built‑in endpoint (longer start‑period for slower startups)
HEALTHCHECK --interval=30s --timeout=10s --start-period=120s --retries=3 \

### Replace the entire Dockerfile with the following content
```dockerfile
# -------------------------------------------------
#  Single‑stage image – install system deps, Python deps, and app
# -------------------------------------------------
FROM python:3.12-slim-bookworm

# Prevent interactive apt prompts
ARG DEBIAN_FRONTEND=noninteractive

# Install all system packages needed for both building wheels and runtime
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        build-essential \
        git \
        pkg-config \
        ca-certificates \
        libssl-dev \
        libffi-dev \
        imagemagick \
        ffmpeg \
        wget \
        curl \
        dos2unix \
        libssl3 \
        libffi8 \
        libgomp1 && \
    rm -rf /var/lib/apt/lists/* && \
    # Relax ImageMagick policy that blocks file I/O (required by some apps)
    sed -i 's/<policy domain="path" rights="none" pattern="@\*"/<policy domain="path" rights="read|write" pattern="@\*"/' /etc/ImageMagick-6/policy.xml || true

# Create a non‑root user and set workdir
WORKDIR /narratoai
RUN groupadd -r narratoai && \
    useradd -r -g narratoai -d /narratoai -s /bin/bash narratoai && \
    chown -R narratoai:narratoai /narratoai

# Set environment for Python
ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONIOENCODING=utf-8 \
    LANG=C.UTF-8 \
    LC_ALL=C.UTF-8

# Copy dependency file and install Python packages
COPY requirements.txt ./
RUN pip install --upgrade pip setuptools wheel && \
    pip install --default-timeout=300 --no-cache-dir -r requirements.txt

# Copy entrypoint and make it executable
COPY docker-entrypoint.sh /usr/local/bin/
RUN dos2unix /usr/local/bin/docker-entrypoint.sh && \
    chmod +x /usr/local/bin/docker-entrypoint.sh

# Copy application source (respect .dockerignore) and fix permissions
COPY --chown=narratoai:narratoai . .

# Create required directories and default config if missing
RUN mkdir -p storage/temp storage/tasks storage/json \
            storage/narration_scripts storage/drama_analysis && \
    if [ ! -f config.toml ]; then cp config.example.toml config.toml; fi && \
    chmod -R 755 /narratoai

# Switch to non‑root user
USER narratoai

# Expose Streamlit default port
EXPOSE 8501

# Health‑check – use Streamlit’s built‑in health endpoint
HEALTHCHECK --interval=30s --timeout=10s --start-period=120s --retries=3 \

### Begin Patch
*** Update File: Dockerfile
-# Health‑check – Streamlit’s built‑in endpoint (longer start‑period for slower startups)
-HEALTHCHECK --interval=30s --timeout=10s --start-period=120s --retries=3 \
-
+# Health‑check – Streamlit’s built‑in endpoint (longer start‑period for slower startups)
+HEALTHCHECK --interval=30s --timeout=10s --start-period=120s --retries=3 \

```dockerfile
# -------------------------------------------------
#  Builder stage – compile and install Python dependencies
# -------------------------------------------------
FROM python:3.12-slim-bookworm AS builder
ARG DEBIAN_FRONTEND=noninteractive
WORKDIR /build

# Install build‑time system packages (compilers, headers, git, etc.)
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        build-essential \
        git \
        pkg-config \
        ca-certificates \
        libssl-dev \
        libffi-dev && \
    rm -rf /var/lib/apt/lists/*

# Create a virtual environment that will be copied to the runtime image
RUN python -m venv /opt/venv && \
    /opt/venv/bin/pip install --upgrade pip setuptools wheel

ENV VIRTUAL_ENV=/opt/venv
ENV PATH="$VIRTUAL_ENV/bin:$PATH"
ENV PIP_NO_CACHE_DIR=1

# Install Python requirements inside the venv
COPY requirements.txt ./
RUN pip install --default-timeout=300 -r requirements.txt

# -------------------------------------------------
#  Runtime stage – lightweight image with app code
# -------------------------------------------------
FROM python:3.12-slim-bookworm AS runtime
ARG DEBIAN_FRONTEND=noninteractive
WORKDIR /narratoai

# Copy the pre‑built virtual environment from the builder
COPY --from=builder /opt/venv /opt/venv

# Install only the runtime system packages (including libs needed by wheels)
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        imagemagick \
        ffmpeg \
        wget \
        curl \
        ca-certificates \
        dos2unix \
        libssl3 \
        libffi8 \
        libgomp1 && \
    rm -rf /var/lib/apt/lists/* && \
    # Relax ImageMagick policy that blocks file I/O (required by some apps)
    sed -i 's/<policy domain="path" rights="none" pattern="@\*"/<policy domain="path" rights="read|write" pattern="@\*"/' /etc/ImageMagick-6/policy.xml || true && \
    # Create a non‑root user and give it ownership of the app directory
    groupadd -r narratoai && \
    useradd -r -g narratoai -d /narratoai -s /bin/bash narratoai

# Make the venv the default Python interpreter and set common env vars
ENV VIRTUAL_ENV=/opt/venv
ENV PATH="$VIRTUAL_ENV/bin:$PATH" \
    PYTHONPATH="/narratoai" \
    PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONIOENCODING=utf-8 \
    LANG=C.UTF-8 \
    LC_ALL=C.UTF-8

# -----------------------------------------------------------------
#  Entrypoint & application files
# -----------------------------------------------------------------
COPY docker-entrypoint.sh /usr/local/bin/
RUN dos2unix /usr/local/bin/docker-entrypoint.sh && \
    chmod +x /usr/local/bin/docker-entrypoint.sh

# Copy the application source (respect .dockerignore) and set correct ownership
COPY --chown=narratoai:narratoai . .

# Create required directories, provide a default config if missing and set permissions
RUN mkdir -p storage/temp storage/tasks storage/json \
            storage/narration_scripts storage/drama_analysis && \
    if [ ! -f config.toml ]; then cp config.example.toml config.toml; fi && \
    chown -R narratoai:narratoai /narratoai && \
    chmod -R 755 /narratoai

# Switch to the non‑root user for running the app
USER narratoai

# -------------------------------------------------
#  Container metadata
# -------------------------------------------------
EXPOSE 8501

# Health‑check – Streamlit’s built‑in endpoint (longer start‑period for slower startups)
HEALTHCHECK --interval=30s --timeout=10s --start-period=120s --retries=3 \

*** Begin Patch
*** Update File: Dockerfile
-# Health‑check – Streamlit’s built‑in endpoint (longer start‑period for slower startups)
-HEALTHCHECK --interval=30s --timeout=10s --start-period=120s --retries=3 \
-
-*** Begin Patch
-*** Update File: Dockerfile
FROM python:3.12-slim-bookworm
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        imagemagick \
        ffmpeg \
        wget \
        curl \
        ca-certificates \
      dos2unix && \
      dos2unix \
      # Runtime equivalents of the build‑time libs needed by compiled wheels
      libssl3 \
      libffi8 \
      # Common runtime deps for scientific / data‑processing wheels
      libgomp1 && \
    # Relax ImageMagick policy that blocks reading/writing of files (needed by some apps)
  rm -rf /var/lib/apt/lists/*
  rm -rf /var/lib/apt/lists/*
-*** End Patch
-
-*** Begin Patch
-*** Update File: Dockerfile
-# -------------------------------------------------
-#  Runtime stage – lightweight image with app code
-# -------------------------------------------------
-FROM python:3.12-slim-bookworm
-
-ARG DEBIAN_FRONTEND=noninteractive
-
-# Application work directory
-WORKDIR /narratoai
-
-# Copy the pre‑built virtual environment from the builder
-COPY --from=builder /opt/venv /opt/venv
-
-# Install only the runtime system packages
-RUN apt-get update && \
  apt-get install -y --no-install-recommends \
      imagemagick \
      ffmpeg \
      wget \
      curl \
      ca-certificates \
      dos2unix && \
  # Relax ImageMagick policy that blocks reading/writing of files (needed by some apps)
  sed -i 's/<policy domain="path" rights="none" pattern="@\*"/<policy domain="path" rights="read|write" pattern="@\*"/' \
      /etc/ImageMagick-6/policy.xml || true && \
  # Create a non‑root user and give it ownership of the app directory
  groupadd -r narratoai && \
  useradd -r -g narratoai -d /narratoai -s /bin/bash narratoai && \
  rm -rf /var/lib/apt/lists/*
-+# -------------------------------------------------
-+#  Runtime stage – lightweight image with app code
-+# -------------------------------------------------
-FROM python:3.12-slim-bookworm AS runtime
-
-ARG DEBIAN_FRONTEND=noninteractive
-
-# Application work directory
-WORKDIR /narratoai
-
-# Copy the pre‑built virtual environment from the builder
-COPY --from=builder /opt/venv /opt/venv
-
-# Install only the runtime system packages (including libraries required by compiled wheels)
-RUN apt-get update && \
  apt-get install -y --no-install-recommends \
      imagemagick \
      ffmpeg \
      wget \
      curl \
      ca-certificates \
      dos2unix \
      libssl3 \
      libffi8 \
      libgomp1 && \
  rm -rf /var/lib/apt/lists/* && \
  # Relax ImageMagick policy that blocks reading/writing of files (needed by some apps)
  sed -i 's/<policy domain="path" rights="none" pattern="@\*"/<policy domain="path" rights="read|write" pattern="@\*"/' \
      /etc/ImageMagick-6/policy.xml || true && \
  # Create a non‑root user and give it ownership of the app directory
  groupadd -r narratoai && \
  useradd -r -g narratoai -d /narratoai -s /bin/bash narratoai
-HEALTHCHECK --interval=30s --timeout=10s --start-period=120s --retries=3 \
-
-*** Begin Patch
-*** Update File: Dockerfile
-FROM python:3.12-slim-bookworm
-RUN apt-get update && \
   apt-get install -y --no-install-recommends \
       imagemagick \
       ffmpeg \
       wget \
       curl \
       ca-certificates \
     dos2unix && \
     dos2unix \
     # Runtime equivalents of the build‑time libs needed by compiled wheels
     libssl3 \
     libffi8 \
     # Common runtime deps for scientific / data‑processing wheels
     libgomp1 && \
   # Relax ImageMagick policy that blocks reading/writing of files (needed by some apps)
 rm -rf /var/lib/apt/lists/*
 rm -rf /var/lib/apt/lists/*
-*** End Patch
-
-### Begin Patch
-*** Update File: Dockerfile
-# Health‑check – Streamlit’s built‑in endpoint (longer start‑period for slower startups)
-HEALTHCHECK --interval=30s --timeout=10s --start-period=120s --retries=3 \
-
-### End Patch
-

```dockerfile
# -------------------------------------------------
#  Builder stage – compile and install Python deps (Alpine)
# -------------------------------------------------
FROM python:3.12-alpine AS builder
ARG BUILD_DEPS="\
    build-base\
    git\
    libffi-dev\
    openssl-dev\
    python3-dev"
ARG RUNTIME_DEPS="\
    libffi\
    openssl"

# Install build‑time packages, create venv, install Python deps, then strip build deps
RUN apk add --no-cache $BUILD_DEPS $RUNTIME_DEPS && \
    python -m venv /opt/venv && \
    /opt/venv/bin/pip install --upgrade pip setuptools wheel && \
    mkdir /app && \
    cp requirements.txt /app/ && \
    cd /app && \
    /opt/venv/bin/pip install --default-timeout=300 -r requirements.txt && \
    # Remove build‑time packages – keep only runtime deps
    apk del $BUILD_DEPS && \
    rm -rf /var/cache/apk/*

ENV VIRTUAL_ENV=/opt/venv
ENV PATH="$VIRTUAL_ENV/bin:$PATH"

# -------------------------------------------------
#  Runtime stage – lightweight Alpine image with app code
# -------------------------------------------------
FROM python:3.12-alpine AS runtime
ARG RUNTIME_DEPS="\
    imagemagick\
    ffmpeg\
    curl\
    wget\
    dos2unix\
    libffi\
    openssl"

WORKDIR /narratoai

# Install runtime system packages
RUN apk add --no-cache $RUNTIME_DEPS && \
    # Relax ImageMagick policy (same sed as before, works on Alpine)
    sed -i 's/<policy domain="path" rights="none" pattern="@\*"/<policy domain="path" rights="read|write" pattern="@\*"/' /etc/ImageMagick-6/policy.xml || true && \
    # Create non‑root user
    addgroup -S narratoai && adduser -S -G narratoai -h /narratoai narratoai

# Copy the pre‑built virtual environment
COPY --from=builder /opt/venv $VIRTUAL_ENV

# Set Python environment variables
ENV VIRTUAL_ENV=$VIRTUAL_ENV
ENV PATH="$VIRTUAL_ENV/bin:$PATH" \
    PYTHONPATH="/narratoai" \
    PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONIOENCODING=utf-8 \
    LANG=C.UTF-8 \
    LC_ALL=C.UTF-8

# -----------------------------------------------------------------
#  Entrypoint & application files
# -----------------------------------------------------------------
COPY docker-entrypoint.sh /usr/local/bin/
RUN dos2unix /usr/local/bin/docker-entrypoint.sh && chmod +x /usr/local/bin/docker-entrypoint.sh

# Copy source code (respect .dockerignore) and set ownership
COPY --chown=narratoai:narratoai . .

# Create required directories and default config if missing
RUN mkdir -p storage/temp storage/tasks storage/json \
            storage/narration_scripts storage/drama_analysis && \
    if [ ! -f config.toml ]; then cp config.example.toml config.toml; fi && \
    chmod -R 755 /narratoai

USER narratoai

EXPOSE 8501

# Health‑check – use Streamlit’s built‑in endpoint
HEALTHCHECK CMD curl -f http://localhost:8501/_stcore/health || exit 1

# Default command – start the Streamlit app

### Remove the broken health‑check block (lines 103‑108) that contain stray *** markers and a trailing back‑slash.
-# Health‑check – Streamlit’s built‑in endpoint (longer start‑period for slower startups)
-HEALTHCHECK --interval=30s --timeout=10s --start-period=120s --retries=3 \
-
-*** Begin Patch
-*** Update File: Dockerfile
FROM python:3.12-slim-bookworm
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        imagemagick \
        ffmpeg \
        wget \
        curl \
        ca-certificates \
      dos2unix && \
      dos2unix \
      # Runtime equivalents of the build‑time libs needed by compiled wheels
      libssl3 \
      libffi8 \
      # Common runtime deps for scientific / data‑processing wheels
      libgomp1 && \
    # Relax ImageMagick policy that blocks reading/writing of files (needed by some apps)
  rm -rf /var/lib/apt/lists/*
  rm -rf /var/lib/apt/lists/*
+# Health‑check – Streamlit’s built‑in endpoint (longer start‑period for slower startups)
+HEALTHCHECK CMD ["sh", "/usr/local/bin/healthcheck.sh"]
+
+### Add a tiny health‑check script that uses curl and respects the desired timing parameters.
+### This file will be copied into the image and executed by the HEALTHCHECK instruction.
+### Create a new file `healthcheck.sh` alongside the Dockerfile with the following content:
+### ---------------------------------------------------------------
+### #!/usr/bin/env sh
+### # Streamlit health endpoint
+### curl -f http://localhost:8501/_stcore/health || exit 1
+### ---------------------------------------------------------------
+### Then add the copy step below (placed near the other COPY commands).
+
+COPY healthcheck.sh /usr/local/bin/healthcheck.sh
+RUN chmod +x /usr/local/bin/healthcheck.sh

```dockerfile
# -------------------------------------------------
# Builder stage – compile and install Python dependencies
# -------------------------------------------------
FROM python:3.12-slim-bookworm AS builder
ARG DEBIAN_FRONTEND=noninteractive
WORKDIR /build

# Install build‑time system packages (compilers, headers, git, etc.)
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        build-essential \
        git \
        pkg-config \
        ca-certificates \
        libssl-dev \
        libffi-dev && \
    rm -rf /var/lib/apt/lists/*

# Create a virtual environment that will be copied to the runtime image
RUN python -m venv /opt/venv && \
    /opt/venv/bin/pip install --upgrade pip setuptools wheel

ENV VIRTUAL_ENV=/opt/venv
ENV PATH="$VIRTUAL_ENV/bin:$PATH"
ENV PIP_NO_CACHE_DIR=1

# Install Python requirements inside the venv
COPY requirements.txt ./
RUN pip install --default-timeout=300 -r requirements.txt

# -------------------------------------------------
# Runtime stage – lightweight image with app code
# -------------------------------------------------
FROM python:3.12-slim-bookworm AS runtime
ARG DEBIAN_FRONTEND=noninteractive
WORKDIR /narratoai

# Copy the pre‑built virtual environment from the builder
COPY --from=builder /opt/venv /opt/venv

# Install only the runtime system packages (including libs needed by wheels)
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        imagemagick \
        ffmpeg \
        wget \
        curl \
        ca-certificates \
        dos2unix \
        libssl3 \
        libffi8 \
        libgomp1 && \
    rm -rf /var/lib/apt/lists/* && \
    # Relax ImageMagick policy that blocks file I/O (required by some apps)
    sed -i 's/<policy domain="path" rights="none" pattern="@\*"/<policy domain="path" rights="read|write" pattern="@\*"/' /etc/ImageMagick-6/policy.xml || true && \
    # Create a non‑root user and give it ownership of the app directory
    groupadd -r narratoai && \
    useradd -r -g narratoai -d /narratoai -s /bin/bash narratoai

# Make the venv the default Python interpreter and set common env vars
ENV VIRTUAL_ENV=/opt/venv
ENV PATH="$VIRTUAL_ENV/bin:$PATH" \
    PYTHONPATH="/narratoai" \
    PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONIOENCODING=utf-8 \
    LANG=C.UTF-8 \
    LC_ALL=C.UTF-8

# -----------------------------------------------------------------
# Entrypoint & application files
# -----------------------------------------------------------------
COPY docker-entrypoint.sh /usr/local/bin/
RUN dos2unix /usr/local/bin/docker-entrypoint.sh && chmod +x /usr/local/bin/docker-entrypoint.sh

# Copy the application source (respect .dockerignore) and set correct ownership
COPY --chown=narratoai:narratoai . .

# Create required directories, provide a default config if missing and set permissions
RUN mkdir -p storage/temp storage/tasks storage/json \
            storage/narration_scripts storage/drama_analysis && \
    if [ ! -f config.toml ]; then cp config.example.toml config.toml; fi && \
    chown -R narratoai:narratoai /narratoai && \
    chmod -R 755 /narratoai

# Switch to the non‑root user for running the app
USER narratoai

# -------------------------------------------------
# Container metadata
# -------------------------------------------------
EXPOSE 8501

# Health‑check – Streamlit’s built‑in endpoint
HEALTHCHECK CMD curl -f http://localhost:8501/_stcore/health || exit 1

# Default command – start the Streamlit app

# -------------------------------------------------
#  Builder stage – compile and install Python dependencies
# -------------------------------------------------
FROM python:3.12-slim-bookworm AS builder
ARG DEBIAN_FRONTEND=noninteractive
WORKDIR /app

# Install build‑time system packages (compilers, headers, git, etc.)
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        build-essential \
        git \
        pkg-config \
        ca-certificates \
        libssl-dev \
        libffi-dev && \
    rm -rf /var/lib/apt/lists/*

# Create a virtual environment that will be copied to the runtime image
RUN python -m venv /opt/venv
ENV VIRTUAL_ENV=/opt/venv
ENV PATH="$VIRTUAL_ENV/bin:$PATH"

# Upgrade pip and install Python requirements inside the venv
COPY requirements.txt .
RUN pip install --upgrade pip setuptools wheel && \
    pip install --no-cache-dir -r requirements.txt

# -------------------------------------------------
#  Runtime stage – lightweight image with app code
# -------------------------------------------------
FROM python:3.12-slim-bookworm AS runtime
ARG DEBIAN_FRONTEND=noninteractive
WORKDIR /narratoai

# Copy the pre‑built virtual environment from the builder
COPY --from=builder /opt/venv /opt/venv
ENV VIRTUAL_ENV=/opt/venv
ENV PATH="$VIRTUAL_ENV/bin:$PATH"

# Install only the runtime system packages (including libs needed by wheels)
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        imagemagick \
        ffmpeg \
        wget \
        curl \
        ca-certificates \
        dos2unix \
        libssl3 \
        libffi8 \
        libgomp1 && \
    rm -rf /var/lib/apt/lists/* && \
    # Relax ImageMagick policy that blocks file I/O (required by some apps)
    sed -i 's/<policy domain="path" rights="none" pattern="@\*"/<policy domain="path" rights="read|write" pattern="@\*"/' /etc/ImageMagick-6/policy.xml || true && \
    # Create a non‑root user and give it ownership of the app directory
    groupadd -r narratoai && \
    useradd -r -g narratoai -d /narratoai -s /bin/bash narratoai

# -----------------------------------------------------------------
#  Entrypoint & application files
# -----------------------------------------------------------------
COPY docker-entrypoint.sh /usr/local/bin/
RUN dos2unix /usr/local/bin/docker-entrypoint.sh && chmod +x /usr/local/bin/docker-entrypoint.sh

# Copy the application source (respect .dockerignore) and set correct ownership
COPY --chown=narratoai:narratoai . .

# Create required directories, provide a default config if missing and set permissions
RUN mkdir -p storage/temp storage/tasks storage/json storage/narration_scripts storage/drama_analysis && \
    if [ ! -f config.toml ]; then cp config.example.toml config.toml; fi && \
    chown -R narratoai:narratoai /narratoai && \
    chmod -R 755 /narratoai

USER narratoai

# -------------------------------------------------
#  Container metadata
# -------------------------------------------------
EXPOSE 8501

# Health‑check – Streamlit built‑in endpoint (single‑line, valid syntax)
HEALTHCHECK --interval=30s --timeout=10s --start-period=120s --retries=3 CMD curl -f http://localhost:8501/_stcore/health || exit 1

# -------------------------------------------------
#  Builder stage – compile and install Python dependencies
# -------------------------------------------------
FROM python:3.12-slim-bookworm AS builder
ARG DEBIAN_FRONTEND=noninteractive
WORKDIR /build

# Install build‑time system packages (compilers, headers, git, etc.)
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        build-essential \
        git \
        pkg-config \
        ca-certificates \
        libssl-dev \
        libffi-dev && \
    rm -rf /var/lib/apt/lists/*

# Create a virtual environment that will be copied to the runtime image
RUN python -m venv /opt/venv && \
    /opt/venv/bin/pip install --upgrade pip setuptools wheel

ENV VIRTUAL_ENV=/opt/venv
ENV PATH="$VIRTUAL_ENV/bin:$PATH"
ENV PIP_NO_CACHE_DIR=1

# Install Python requirements inside the venv
COPY requirements.txt .
RUN pip install --default-timeout=300 -r requirements.txt

# -------------------------------------------------
#  Runtime stage – lightweight image with app code
# -------------------------------------------------
FROM python:3.12-slim-bookworm AS runtime
ARG DEBIAN_FRONTEND=noninteractive
WORKDIR /narratoai

# Copy the pre‑built virtual environment from the builder
COPY --from=builder /opt/venv /opt/venv

# Install only the runtime system packages (including libs needed by wheels)
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        imagemagick \
        ffmpeg \
        wget \
        curl \
        ca-certificates \
        dos2unix \
        libssl3 \
        libffi8 \
        libgomp1 && \
    rm -rf /var/lib/apt/lists/* && \
    # Relax ImageMagick policy that blocks file I/O (required by some apps)
    sed -i 's/<policy domain="path" rights="none" pattern="@\*"/<policy domain="path" rights="read|write" pattern="@\*"/' /etc/ImageMagick-6/policy.xml || true && \
    # Create a non‑root user and give it ownership of the app directory
    groupadd -r narratoai && \
    useradd -r -g narratoai -d /narratoai -s /bin/bash narratoai

# Make the venv the default Python interpreter and set common env vars
ENV VIRTUAL_ENV=/opt/venv
ENV PATH="$VIRTUAL_ENV/bin:$PATH" \
    PYTHONPATH="/narratoai" \
    PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONIOENCODING=utf-8 \
    LANG=C.UTF-8 \
    LC_ALL=C.UTF-8

# -----------------------------------------------------------------
#  Entrypoint & application files
# -----------------------------------------------------------------
COPY docker-entrypoint.sh /usr/local/bin/
RUN dos2unix /usr/local/bin/docker-entrypoint.sh && chmod +x /usr/local/bin/docker-entrypoint.sh

# Copy the application source (respect .dockerignore) and set correct ownership
COPY --chown=narratoai:narratoai . .

# Create required directories, provide a default config if missing and set permissions
RUN mkdir -p storage/temp storage/tasks storage/json \
            storage/narration_scripts storage/drama_analysis && \
    if [ ! -f config.toml ]; then cp config.example.toml config.toml; fi && \
    chown -R narratoai:narratoai /narratoai && \
    chmod -R 755 /narratoai

# Switch to the non‑root user for running the app
USER narratoai

# -------------------------------------------------
#  Container metadata
# -------------------------------------------------
EXPOSE 8501

# Health‑check – Streamlit’s built‑in endpoint
HEALTHCHECK CMD curl -f http://localhost:8501/_stcore/health || exit 1

# Default command – start the Streamlit app
ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
CMD ["streamlit", "run", "app.py", "--server.port=8501", "--server.address=0.0.0.0"]

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
CMD ["streamlit", "run", "app.py", "--server.port=8501", "--server.address=0.0.0.0"]

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
CMD ["streamlit", "run", "app.py", "--server.port=8501", "--server.address=0.0.0.0"]
```

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
CMD ["streamlit", "run", "app.py", "--server.port=8501", "--server.address=0.0.0.0"]
```

   CMD curl -f http://localhost:8501/_stcore/health || exit 1
+# Health‑check – Streamlit’s built‑in endpoint (longer start‑period for slower startups)
+HEALTHCHECK --interval=30s \
           --timeout=10s \
           --start-period=120s \
           --retries=3 \
           CMD curl -f http://localhost:8501/_stcore/health || exit 1
*** End Patch
*** End Patch

  CMD curl -f http://localhost:8501/_stcore/health || exit 1

# Default command – start the Streamlit app
ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
CMD ["streamlit", "run", "app.py", "--server.port=8501", "--server.address=0.0.0.0"]
```

 CMD curl -f http://localhost:8501/_stcore/health || exit 1
*** End Patch
### End Patch

    CMD curl -f http://localhost:8501/_stcore/health || exit 1

# Default command
ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
CMD ["streamlit", "run", "app.py", "--server.port=8501", "--server.address=0.0.0.0"]
```

    CMD curl -f http://localhost:8501/_stcore/health || exit 1

# Default command – start the Streamlit app
ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
CMD ["streamlit", "run", "app.py", "--server.port=8501", "--server.address=0.0.0.0"]
```

   CMD curl -f http://localhost:8501/_stcore/health || exit 1
+HEALTHCHECK --interval=30s --timeout=10s --start-period=120s --retries=3 \
 CMD curl -f http://localhost:8501/_stcore/health || exit 1
*** End Patch
*** End Patch

    CMD curl -f http://localhost:8501/_stcore/health || exit 1

# Default command – start the Streamlit app
ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
CMD ["streamlit", "run", "app.py", "--server.port=8501", "--server.address=0.0.0.0"]