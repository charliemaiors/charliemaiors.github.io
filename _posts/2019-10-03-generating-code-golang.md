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

Cobra is a standard de-facto for CLI applications developed in Golang, among the different projects which uses cobra we can find the [Kubernetes](https://kubernetes.io/) CLI, [Docker](https://www.docker.com/).  
Cobra has also a practical CLI generator (which is written using cobra itself) to define your project structure, it can be installed using ``go get -u github.com/spf13/cobra/cmd`` and then run ``cobra init <project-name>``.   
Cobra supports all the main features for a CLI application:

* Flags and pflags
* Usage and flags documentation generation
* Subcommands with relative documentation generation
* A deep integration with [Viper](https://github.com/spf13/viper) to handle configurations and binding with environment variables for flag substitution.

Cobra, as far as I've tested, supports also Go [modules](https://blog.golang.org/using-go-modules) in order to create a new CLI application outside the `GOPATH`.

## Jennifer: a pretty straigh forward code generation library

[Jennifer](https://github.com/dave/jennifer) is a simple library to generate code in golang, it supports the definition of all AST structures:

* Functions
* Multiples assignments
* and so on...

Also it supports automatic imports (using the `Qual()` function) and is intrisecally integrated with CI/CD tools because of the compilation phase after the code generation,wich could be a pre-test environment.
For instance the user can generate a new file with all imports like this (taken from Jennifer documentation):

```golang
f := NewFilePath("a.b/c")
f.Func().Id("init").Params().Block(
	Qual("a.b/c", "Foo").Call().Comment("Local package - name is omitted."),
	Qual("d.e/f", "Bar").Call().Comment("Import is automatically added."),
	Qual("g.h/f", "Baz").Call().Comment("Colliding package name is renamed."),
)
fmt.Printf("%#v", f)

// Output:
// package c
//
// import (
// 	f "d.e/f"
// 	f1 "g.h/f"
// )
//
// func init() {
// 	Foo()    // Local package - name is omitted.
// 	f.Bar()  // Import is automatically added.
// 	f1.Baz() // Colliding package name is renamed.
// }
```

## A pratical example

Personally I've used Jennifer, with Cobra, for a project during my research career. I had to write a client (in Golang) for the [Shinobi Platform](https://shinobi.video/) in order to interact with it using the APIs, in particular shinobi offers a lot of configuration to connect a new IP camera to the system. I need to have a map with all the possible configurations in order to programmatically define a new camera via API.  
The project starts with the configuration of the new camera enabling the user to define a new monitored host. The client needs a data structure to grab the correct combination of camera brand and desired stream, in order to expose a properly formatted list of camera streaming options. First of all you have to clone the [gitab repo](https://gitlab.com/Shinobi-Systems/cameraConnectionList) of the camera connection list, then write a parser for the repo structure which is pretty straight forward (for instance [here](https://gitlab.com/charliemaiors/shinobi-param-generator/tree/master/parser) you can find a first version of it).  
Then you have to model, using the Jennifer generator library, your data structure and the related methods, for instance we can define `struct` for the baseline:

```go
  file := jen.NewFilePathName(dest, pkg) //define the destination file
	file.Comment("This is a generated file for mapping shinobi params from param source, DO NOT EDIT!!!") //comment it!!!

	file.Comment("Path represent a path with given default values if present")
	file.Type().Id("Path").Struct( //Define your custom data structures
		jen.Id("IsSecure").Bool(),
		jen.Id("SubPath").String(),
	)

	file.Comment("//Codec represent a subset of paths for a given codec")
	file.Type().Id("Codec").Struct(
		jen.Id("CodecType").String(),
		jen.Id("Paths").Index().Id("Path"),
	)

	file.Comment("//Protocol is the structure which represent a particular IPCam with it's vendor, protocol, codec and relative subpath")
	file.Type().Id("Protocol").Struct(
		jen.Id("Connection").String(),
		jen.Id("Models").Index().String(),
		jen.Id("Codecs").Id("[]Codec"),
	)

	file.Var().Id("paramsMap").Op("=").Map(jen.String()).Id("[]Protocol").Values(generator.generateDict(params))

```

Then you can also define your public and private functions:

```go
  file.Comment("//TakeAllPathsForVendorWithProtocol takes vendor and protocol and select the possibles values from paramsMap")
	file.Func().Id("TakeAllPathsForVendorWithProtocol").Params(jen.Id("vendor").String(), jen.Id("protocol").String()).Parens(jen.Id("Protocol").Op(",").Error()).Block(
		jen.Id("protocolsForVendor").Op(":=").Id("paramsMap").Id("[vendor]"),
		jen.For(jen.Id("_").Op(",").Id("current").Op(":=").Range().Id("protocolsForVendor")).Block(
			jen.If(jen.Id("current").Op(".").Id("Connection").Op("==").Id("protocol")).Block(
				jen.Return(jen.Id("current"), jen.Nil()),
			),
		),
		jen.Return(jen.Id("Protocol{}"), jen.Qual("errors", "New").Call(jen.Lit("No protocol found"))),
	)

	file.Comment("//TakeProtocolForModel takes vendor and model and select the correspondent protocol")
	file.Func().Id("TakeProtocolForModel").Params(jen.Id("model").String(), jen.Id("vendor").String()).Parens(jen.Id("Protocol").Op(",").Error()).Block(
		jen.Id("protocolsForVendor").Op(":=").Id("paramsMap").Id("[vendor]"),
		jen.For(jen.Id("_").Op(",").Id("protocol").Op(":=").Range().Id("protocolsForVendor")).Block(
			jen.If(jen.Qual(pkg, "containsModel").Call(jen.Id("protocol").Op(".").Id("Models"), jen.Id("model"))).Block(
				jen.Return(jen.Id("protocol"), jen.Nil()),
			),
		),
		jen.Return(jen.Id("Protocol{}"), jen.Qual("errors", "New").Call(jen.Lit("No protocol found"))),
	)

```

For the public part,and the following for the private part:

```go
  file.Func().Id("containsModel").Params(jen.Id("models").Id("[]string"),      jen.Id("model").String()).Bool().Block(
		jen.For(jen.Id("_").Op(",").Id("mod").Op(":=").Range().Id("models").Block(
			jen.If(jen.Id("mod").Op("==").Id("model").Block(
				jen.Return(jen.True()),
			)),
		)),
		jen.Return(jen.False()),
	)

```

The full generator code is available [here](https://gitlab.com/charliemaiors/shinobi-param-generator/tree/master/generator).