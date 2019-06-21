---
layout: post
title:  "A simple go generate example with Cobra and Jennifer"
comments: true
categories: golang
sharing:
  twitter: A simple go generate example with Cobra and Jennifer
---

# The ``go generate`` command

Golang is the most used programming language in distributed and concurrent systems, it is mainly used to write services and command line applications. Golang, as many other programming languages, is Turing complete, this means that the developer could write go code which write (or traditionally defined as generate) go code. Tipically this feature is not so much appreciated as might be, but under the hood is used by many tools like the compiler or the test runner; the last one, indeed, scans all the packages that has to be tested, generate a go program containing the test harness, compiles, and run them (source [Golang blog](https://blog.golang.org/generate)).  

- Introduzione a go generate
- Definizione dei passaggi di generazione
- Introduzione a Cobra 
- Introduzione a Jennifer
- Esempio da Gitlab