FROM ubuntu:latest

# Set environment variables to reduce interaction and prevent format building
ENV DEBIAN_FRONTEND=noninteractive \
    LANG=C.UTF-8 \
    LC_ALL=C.UTF-8 \
    TEXLIVE_INSTALL_NO_CONTEXT_CACHE=1 \
    TEXLIVE_INSTALL_NO_FORMATS=1 \
    TEXLIVE_INSTALL_NO_REBUILD=1

# Install basic packages including LWP for faster downloads
RUN apt-get update && apt-get -y install --no-install-recommends \
    apt-utils \
    curl \
    wget \
    perl \
    libwww-perl \
    git \
    make \
    nodejs \
    npm \
    openssh-client \
    procps \
    python3-pkg-resources \
    python3-pygments \
    inkscape \
    tree \
    build-essential \
    libyaml-tiny-perl \
    libfile-homedir-perl \
    liblog-dispatch-perl \
    libunicode-linebreak-perl \
    && apt-get clean -y \
    && rm -rf /var/lib/apt/lists/*

# Install Rust and Cargo
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y \
    && . ~/.cargo/env

# Download and install TeX Live 2025 manually
RUN cd /tmp \
    && wget -O install-tl-unx.tar.gz https://mirror.ctan.org/systems/texlive/tlnet/install-tl-unx.tar.gz \
    && tar -xzf install-tl-unx.tar.gz \
    && cd install-tl-* \
    && echo "selected_scheme scheme-full" > texlive.profile \
    && echo "TEXDIR /usr/local/texlive/2025" >> texlive.profile \
    && echo "TEXMFCONFIG ~/.texlive2025/texmf-config" >> texlive.profile \
    && echo "TEXMFHOME ~/texmf" >> texlive.profile \
    && echo "TEXMFLOCAL /usr/local/texlive/texmf-local" >> texlive.profile \
    && echo "TEXMFSYSCONFIG /usr/local/texlive/2025/texmf-config" >> texlive.profile \
    && echo "TEXMFSYSVAR /usr/local/texlive/2025/texmf-var" >> texlive.profile \
    && echo "TEXMFVAR ~/.texlive2025/texmf-var" >> texlive.profile \
    && echo "option_doc 0" >> texlive.profile \
    && echo "option_src 0" >> texlive.profile \
    && echo "instopt_adjustpath 0" >> texlive.profile \
    && echo "instopt_adjustrepo 1" >> texlive.profile \
    && echo "instopt_letter 0" >> texlive.profile \
    && echo "instopt_portable 0" >> texlive.profile \
    && echo "instopt_write18_restricted 1" >> texlive.profile \
    && perl ./install-tl --profile=texlive.profile --no-interaction \
    && cd / \
    && rm -rf /tmp/install-tl*

# Detect architecture and set PATH accordingly
RUN ARCH=$(uname -m) \
    && if [ "$ARCH" = "x86_64" ]; then \
        TEXLIVE_ARCH="x86_64-linux"; \
    elif [ "$ARCH" = "aarch64" ]; then \
        TEXLIVE_ARCH="aarch64-linux"; \
    else \
        echo "Unsupported architecture: $ARCH" && exit 1; \
    fi \
    && echo "TEXLIVE_ARCH=$TEXLIVE_ARCH" > /etc/texlive-arch

# Set environment variables properly
ENV MANPATH=""
ENV INFOPATH=""

# Install additional tools (without problematic Perl modules)
RUN . /etc/texlive-arch \
    && export PATH="/usr/local/texlive/2025/bin/$TEXLIVE_ARCH:$PATH" \
    && export MANPATH="/usr/local/texlive/2025/texmf-dist/doc/man:$MANPATH" \
    && export INFOPATH="/usr/local/texlive/2025/texmf-dist/doc/info:$INFOPATH" \
    && npm install -g bibtex-tidy playwright \
    && npx playwright install --with-deps chromium \
    && curl -fsSL https://d2lang.com/install.sh | sh -s -- \
    && . ~/.cargo/env \
    && cargo install tex-fmt

# Install additional LaTeX tools using tlmgr
RUN . /etc/texlive-arch \
    && export PATH="/usr/local/texlive/2025/bin/$TEXLIVE_ARCH:$PATH" \
    && tlmgr update --self \
    && tlmgr install latexmk chktex biber

# Set final environment variables for runtime (both architectures in PATH for compatibility)
ENV PATH="/root/.cargo/bin:/usr/local/texlive/2025/bin/x86_64-linux:/usr/local/texlive/2025/bin/aarch64-linux:$PATH"
ENV MANPATH="/usr/local/texlive/2025/texmf-dist/doc/man:$MANPATH"
ENV INFOPATH="/usr/local/texlive/2025/texmf-dist/doc/info:$INFOPATH"

# Reset DEBIAN_FRONTEND to dialog for interactive use if needed
ENV DEBIAN_FRONTEND=dialog

# Verify installation
RUN which tex && which xelatex && which pdflatex && tex --version

