# 🐳 LaTeX Build Container

A multi-platform Docker image based on **Ubuntu** with a full **LaTeX toolchain**, useful CLI utilities, and support for automated bibliography formatting and headless browser testing.

This image is ideal for CI/CD pipelines, academic writing, PDF generation, and automation workflows that require LaTeX and supplementary tools.

---

## 📦 What's Included

This image includes:

- ✅ Full **TeX Live** installation (`texlive-full`)
- ✅ PDF and bibliography tools: `latexmk`, `biber`, `chktex`, `bibtex-tidy`
- ✅ Headless browser support via `Playwright` + Chromium
- ✅ CLI utilities: `git`, `curl`, `make`, `tree`, `procps`, `openssh-client`
- ✅ `Perl` modules: `Log::Dispatch::File`, `YAML::Tiny`, `Unicode::GCString`
- ✅ `Python3` and `Pygments` (syntax highlighting)
- ✅ `Node.js` & `npm`
- ✅ `Inkscape` (for SVG processing)
- ✅ [`d2`](https://d2lang.com) diagram tool

---
