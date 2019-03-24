---
layout: post
title:  "A humble point of view on how to organize persistence in Go"
comments: true
categories: ansible
sharing:
  twitter: A humble point of view on how to organize persistence in Go
  facebook: A humble point of view on how to organize persistence in Go
  linkedin: A humble point of view on how to organize persistence in Go
---

# Persistence in Golang

Currently I'm writing a Telegram Bot in Golang, which requires a persistence layer. Digging around I've found an interesting article of [Alex Edwards](https://www.alexedwards.net/blog/organising-database-access), he depicts three main methods to organize database access:

* Using global variables in the persistence package
* Using a dependency injection like mechanism to inject the ```*sql.DB``` variable
* Define an ```interface``` to define a sort of DAO layer and implement it using a concrete struct which encapsulates the connection pool (the ```*sql.DB``` instance)

The first approach is for a small project or a 'quick-and-dirty' prototyping without any encapsulation or environment enforcing.
The second one, instead, expects to have all handlers in a single package wrapping all the handlers instances to a single structure (for example ```Env```); this structure has all the public methods for the handlers package.
The third method, in my humble opinion, is the best one; defining an interface (or more than one depending on the organization of the tables)  which hides the database access and enables all the possible tuning, this method is also useful (as explained in the article) to define a mock model for other package testing without the necessity to have a database instance on the CI/CD environment. Each interface implementation has its instance of ```*sql.DB``` (aka the connection pool).

## A small improvment

The ```*sql.DB``` is thread safe by design, having a ```sync.Mutex``` field in the struct.

```go
type DB struct {
  ...
	mu           sync.Mutex
  ...
}
```

Which protects and regulate the access to the connection pool.
Exploiting this feature

