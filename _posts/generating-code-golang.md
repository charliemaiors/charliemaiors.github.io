---
layout: post
title:  "A simple go generate example with Cobra and Jennifer"
comments: true
categories: golang
sharing:
  twitter: A simple go generate example with Cobra and Jennifer
---

# The ``go generate`` command

Golang is the most used programming language in distributed and concurrent systems, it is mainly used to write services and command line applications. Golang, as many other programming languages, is Turing complete, this means that the developer could write go code which write (or traditionally defined as generate) go code. Tipically this feature is not so much appreciated as might be, but under the hood is used by many tools like the compiler or the test runner; the last one, indeed, scans all the packages that has to be tested, generate a go program containing the test harness, compiles, and run it (source [Golang blog](https://blog.golang.org/generate)).  
There are a lot of tools which generates code, from [``stringer``](golang.org/x/tools/cmd/stringer) which generates the implementation of ``stringer`` interface (the ``String()`` method) passing through [``jsonenums``](https://github.com/campoy/jsonenums) which generates the ``MarshalJson()`` and ``UnmarshalJson()`` methods for json de/serializations till [``Yacc``](https://golang.org/x/tools/cmd/goyacc) which generate the parser for your language grammar.  
These tools are CLI applications which takes as parameters files, data types and so on; typically these apps must be invoked using the cli like normal executables and uses pflags as params. Golang takes into account also an automatization process to generate the code using a comment ``go:generate <your-generate-app> <params>`` which will be parsed by the ``go generate`` command and invoked

- Introduzione a go generate
- Definizione dei passaggi di generazione
- Introduzione a Cobra 
- Introduzione a Jennifer
- Esempio da Gitlab