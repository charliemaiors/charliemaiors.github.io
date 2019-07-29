---
layout: post
title:  "A simple go generate example with Cobra and Jennifer"
comments: true
categories: golang
sharing:
  twitter: A simple go generate example with Cobra and Jennifer
---

# The `go generate` command

Golang is the most used programming language in distributed and concurrent systems, it is mainly used to write services and command line applications. Golang, as many other programming languages, is Turing complete, this means that the developer could write go code which write (or traditionally defined as generate) go code. Tipically this feature is not so much appreciated as might be, but under the hood is used by many tools like the compiler or the test runner; the last one, indeed, scans all the packages that has to be tested, generate a go program containing the test harness, compiles, and run it (source [Golang blog](https://blog.golang.org/generate)).  
There are a lot of tools which generates code, from [``stringer``](golang.org/x/tools/cmd/stringer) which generates the implementation of ``stringer`` interface (the ``String()`` method) passing through [``jsonenums``](https://github.com/campoy/jsonenums) which generates the ``MarshalJson()`` and ``UnmarshalJson()`` methods for json de/serializations till [``Yacc``](https://golang.org/x/tools/cmd/goyacc) which generate the parser for your language grammar.  
These tools are CLI applications which takes as parameters files, data types and so on; typically these apps must be invoked using the cli like normal executables and uses pflags as params. Golang takes into account also an automatization process to generate the code using a comment ``go:generate <your-generator-app> <params>`` which will be parsed by the ``go generate`` command and invoked as normal executable, so is normal that your executable must be in your PATH (tipically is in your GOPATH).  
For instance you may want to generate the `String()` method, which corresponds to the `Stringer` interface implementation, using a generator; in particular using the `stringer` generator. The developer could choose to do it manually using:

```bash
cd $GOPATH/src/<your-full-service-path> # or cd <your-app-path> if you are using modules
stringer -type=<your-type-that-needs-String>
```

Or it can be done automatically adding a comment in the source file and a step in the compilation pipeline:

```go
//go:generate stringer -type=Whatever

type Whatever struct {
  What string
  Ever int
}
```

And then add this step in your CI/CD pipeline (or simply do it automatically in the root folder of your project):

```bash
go generate
go build -o whatever <your-main-file>.go
```

## A simple introduction to [Cobra](http://github.com/spf13/cobra)

Cobra is a standard de-facto for CLI applications developed in Golang, among the different projects which uses cobra we can find the [Kubernetes](https://kubernetes.io/) CLI.  
Cobra has also a practical CLI generator (which is written using cobra itself) to define your project structure, it can be installed using ``go get -u github.com/spf13/cobra/cmd`` and then run ``cobra init <project-name>``.   
Cobra supports all the main features for a CLI application:

* Flags and pflags
* Usage and flags documentation generation
* Subcommands with relative documentation generation
* A deep integration with [Viper](https://github.com/spf13/viper) to handle configuration and binding with environment variables for flag substitution.



- Introduzione a Cobra 
- Introduzione a Jennifer
- Esempio da Gitlab