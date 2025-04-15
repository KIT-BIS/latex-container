FROM ubuntu:latest

ENV DEBIAN_FRONTEND=noninteractive LANG=C.UTF-8 LC_ALL=C.UTF-8
ENV TEXLIVE_INSTALL_NO_CONTEXT_CACHE=1
ENV TEXLIVE_INSTALL_NO_FORMATS=1


RUN apt-get update && apt-get -y install --no-install-recommends \
    apt-utils \
    biber \
    chktex \
    curl \
    git \
    latexmk \
    make \
    nodejs \
    npm \
    procps \
    python3-pkg-resources \
    python3-pygments \
    texlive-extra-utils \
    texlive-fonts-extra \
    texlive-fonts-recommended \
    texlive-latex-base \
    texlive-latex-extra \
    tree \
    openssh-client \
    && curl -L http://cpanmin.us | perl - App::cpanminus \
    && cpanm Log::Dispatch::File \
    && cpanm YAML::Tiny \
    && cpanm File::HomeDir \
    && cpanm Unicode::GCString \
    && npm install -g bibtex-tidy playwright \
    && npx playwright install --with-deps chromium \
    && curl -fsSL https://d2lang.com/install.sh | sh -s -- \
    && apt-get autoremove -y \
    && apt-get clean -y \
    && rm -rf /var/lib/apt/lists/*
    
RUN  apt-get update && apt-get install -y texlive-full

RUN apt-get update && apt-get -y install --no-install-recommends inkscape \
    && apt-get autoremove -y \
    && apt-get clean -y \
    && rm -rf /var/lib/apt/lists/*

ENV DEBIAN_FRONTEND=dialog
