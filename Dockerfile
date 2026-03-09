FROM ubuntu:latest

# ---------------------------------------------------------------------------- #
#  Base environment
# ---------------------------------------------------------------------------- #
ENV DEBIAN_FRONTEND=noninteractive \
    LANG=C.UTF-8 \
    LC_ALL=C.UTF-8 \
    TEXLIVE_INSTALL_NO_CONTEXT_CACHE=1 \
    TEXLIVE_INSTALL_NO_FORMATS=1 \
    TEXLIVE_INSTALL_NO_REBUILD=1

# ---------------------------------------------------------------------------- #
#  System packages
# ---------------------------------------------------------------------------- #
RUN apt-get update && apt-get install -y --no-install-recommends \
    apt-utils \
    build-essential \
    curl \
    git \
    inkscape \
    jq \
    libyaml-tiny-perl \
    libfile-homedir-perl \
    liblog-dispatch-perl \
    libwww-perl \
    libunicode-linebreak-perl \
    make \
    nodejs \
    npm \
    openssh-client \
    pdf2svg \
    perl \
    poppler-utils \
    procps \
    python3-pkg-resources \
    python3-pygments \
    tree \
    wget \
    && apt-get clean -y \
    && rm -rf /var/lib/apt/lists/*

# ---------------------------------------------------------------------------- #
#  glab – GitLab CLI (multi-arch)
# ---------------------------------------------------------------------------- #
RUN ARCH=$(uname -m) \
    && if [ "$ARCH" = "x86_64" ]; then \
        GLAB_ARCH="amd64"; \
    elif [ "$ARCH" = "aarch64" ]; then \
        GLAB_ARCH="arm64"; \
    else \
        echo "Unsupported architecture: $ARCH" && exit 1; \
    fi \
    && GLAB_VERSION=$(curl -fsSL \
        "https://gitlab.com/api/v4/projects/gitlab-org%2Fcli/releases?per_page=1" \
        | jq -r '.[0].tag_name' | sed 's/^v//') \
    && curl -fsSL \
        "https://gitlab.com/gitlab-org/cli/-/releases/v${GLAB_VERSION}/downloads/glab_${GLAB_VERSION}_linux_${GLAB_ARCH}.deb" \
        -o /tmp/glab.deb \
    && dpkg -i /tmp/glab.deb \
    && rm /tmp/glab.deb

# ---------------------------------------------------------------------------- #
#  Rust / Cargo
# ---------------------------------------------------------------------------- #
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs \
    | sh -s -- -y --no-modify-path
ENV PATH="/root/.cargo/bin:$PATH"

# ---------------------------------------------------------------------------- #
#  TeX Live 2025 – full scheme, no docs/src
# ---------------------------------------------------------------------------- #
RUN cd /tmp \
    && wget -q -O install-tl-unx.tar.gz \
        https://mirror.ctan.org/systems/texlive/tlnet/install-tl-unx.tar.gz \
    && tar -xzf install-tl-unx.tar.gz \
    && cd install-tl-* \
    && printf '%s\n' \
        'selected_scheme scheme-full' \
        'TEXDIR /usr/local/texlive/2025' \
        'TEXMFCONFIG ~/.texlive2025/texmf-config' \
        'TEXMFHOME ~/texmf' \
        'TEXMFLOCAL /usr/local/texlive/texmf-local' \
        'TEXMFSYSCONFIG /usr/local/texlive/2025/texmf-config' \
        'TEXMFSYSVAR /usr/local/texlive/2025/texmf-var' \
        'TEXMFVAR ~/.texlive2025/texmf-var' \
        'option_doc 0' \
        'option_src 0' \
        'instopt_adjustpath 0' \
        'instopt_adjustrepo 1' \
        'instopt_letter 0' \
        'instopt_portable 0' \
        'instopt_write18_restricted 1' \
        > texlive.profile \
    && perl ./install-tl --profile=texlive.profile --no-interaction \
    && cd / \
    && rm -rf /tmp/install-tl*

# ---------------------------------------------------------------------------- #
#  Persist the arch-specific TeX Live bin path for later RUN steps
# ---------------------------------------------------------------------------- #
RUN ARCH=$(uname -m) \
    && if [ "$ARCH" = "x86_64" ]; then \
        TEXLIVE_ARCH="x86_64-linux"; \
    elif [ "$ARCH" = "aarch64" ]; then \
        TEXLIVE_ARCH="aarch64-linux"; \
    else \
        echo "Unsupported architecture: $ARCH" && exit 1; \
    fi \
    && printf 'export TEXLIVE_ARCH=%s\nexport PATH=/usr/local/texlive/2025/bin/%s:$PATH\n' \
        "$TEXLIVE_ARCH" "$TEXLIVE_ARCH" > /etc/texlive-arch

# ---------------------------------------------------------------------------- #
#  Additional tools that need TeX Live or Cargo on PATH
# ---------------------------------------------------------------------------- #
RUN . /etc/texlive-arch \
    && npm install -g bibtex-tidy playwright \
    && npx playwright install --with-deps chromium \
    && curl -fsSL https://d2lang.com/install.sh | sh -s -- \
    && cargo install tex-fmt

# ---------------------------------------------------------------------------- #
#  Extra LaTeX packages via tlmgr
# ---------------------------------------------------------------------------- #
RUN . /etc/texlive-arch \
    && tlmgr update --self \
    && tlmgr install latexmk chktex biber

# ---------------------------------------------------------------------------- #
#  Runtime environment
# ---------------------------------------------------------------------------- #
ENV PATH="/root/.cargo/bin:/usr/local/texlive/2025/bin/x86_64-linux:/usr/local/texlive/2025/bin/aarch64-linux:$PATH"
ENV MANPATH="/usr/local/texlive/2025/texmf-dist/doc/man:"
ENV INFOPATH="/usr/local/texlive/2025/texmf-dist/doc/info:"
ENV DEBIAN_FRONTEND=dialog

# ---------------------------------------------------------------------------- #
#  Smoke test
# ---------------------------------------------------------------------------- #
RUN which tex && which xelatex && which pdflatex && tex --version && glab --version
