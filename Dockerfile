FROM ubuntu:latest

# Set environment variables to reduce interaction and prevent format building
ENV DEBIAN_FRONTEND=noninteractive \
    LANG=C.UTF-8 \
    LC_ALL=C.UTF-8 \
    TEXLIVE_INSTALL_NO_CONTEXT_CACHE=1 \
    TEXLIVE_INSTALL_NO_FORMATS=1 \
    TEXLIVE_INSTALL_NO_REBUILD=1

# Install packages in a single layer to reduce image size
RUN apt-get update && apt-get -y install --no-install-recommends \
    apt-utils \
    biber \
    chktex \
    curl \
    git \
    inkscape \
    latexmk \
    make \
    nodejs \
    npm \
    openssh-client \
    procps \
    python3-pkg-resources \
    python3-pygments \
    texlive-full \
    tree \
    && curl -L http://cpanmin.us | perl - App::cpanminus \
    && cpanm Log::Dispatch::File YAML::Tiny File::HomeDir Unicode::GCString \
    && npm install -g bibtex-tidy playwright \
    && npx playwright install --with-deps chromium \
    && curl -fsSL https://d2lang.com/install.sh | sh -s -- \
    && apt-get autoremove -y \
    && apt-get clean -y \
    && rm -rf /var/lib/apt/lists/*

# Reset DEBIAN_FRONTEND to dialog for interactive use if needed
ENV DEBIAN_FRONTEND=dialog