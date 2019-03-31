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
The third method, in my humble opinion, is the best one; defining an interface (or more than one depending on the organization of the tables)  which hides the database access and enables all the possible tuning, this method is also useful (as explained in the article) to define a mock model for other package testing without the necessity to have a database instance on the CI/CD environment. Each interface implementation has its instance of ```*sql.DB``` (aka the connection pool). There is also a fourth method which enables to spread around the connection pool using the [context](https://golang.org/pkg/context/) package, but (as the author) I'm not a big fun of use application context for internal objects instead of "business" variables.

## A small improvment to interface model

The ```*sql.DB``` is thread safe by design, having a ```sync.Mutex``` field in the struct.

```go
type DB struct {
  ...
	mu           sync.Mutex
  ...
}
```

Which protects and regulate the access to the connection pool. During a "brainstorm" conversation with a [co-worker](https://twitter.com/mcilloni), we thought to separe the connection pool from the interface implementation using a channel of function as intermediate; then run all received functions in a goroutine because of the thread-safety of ```*sql.DB``` package. \
How it extends the interface method? We assumed to have a ```persistence``` package where the developer should put all the logic regarding database interaction, so for each database entity the developer could define an interface to "interact" with it. I will use the data structures and functions defined in the Alex's blog post.

```go
type Book struct {
    Isbn   string
    Title  string
    Author string
    Price  float32
}

type BooksPersistor interface {
    AllBooks() ([]*Book, error)
}
```

Now we will define the function which handles the database interaction.

```go
var dbhandlerChan = make(chan func(db *sql.DB))

func startHandler(db *sql.DB){
  for dbfunction := range dbchan {
    go dbfunction(handler)
  }
}
```

Then we will implement the `BookPersistor` interface for Postgresql.

```go
type postgresBookPersistor struct {
  // store private variables if needed
}

func (persistor *postgresBookPersistor) awaitAndReturn(resChan chan []*Book, errChan chan error) ([]*Book, error){
  select{
    case books :=<-resChan:
      return books, nil
    case err :=<- errChan:
      return nil, err
  }
}

func (persistor *postgresBookPersistor) AllBooks() ([]*Book, error){
  booksChan := make(chan []*Books)
  errChan := make(chan error)
  defer close(booksChan)
  defer close(errChan)
  dbFunc := func(db *sql.DB){
    rows, err := db.Query("SELECT * FROM books")
    if err != nil {
        return nil, err
    }
    defer rows.Close()

    bks := make([]*Book, 0)
    for rows.Next() {
        bk := new(Book)
        err := rows.Scan(&bk.Isbn, &bk.Title, &bk.Author, &bk.Price)
        if err != nil {
            return nil, err
        }
        bks = append(bks, bk)
    }
    if err = rows.Err(); err != nil {
        return nil, err
    }
    return bks, nil
  }
  return persistor.awaitAndReturn(booksChan,errChan)
}
```

We have also to implement a method for instantiate the "postgres part" of the persistence module:

```go
func initPostgres() BookPersistor{
  db, err := sql.Open("postgres", dataSourceName) //NOTE the datasource could be obtained using viper, env variables or whatever
  if err != nil {
    panic(err)
  }
  go startHandler(db)
  return postgresBookPersistor{}
}
```

Then to instantiate the persistence module you can have a ```StartPersistence(dbtype string)``` method which instantiate the interfaces for the correct db.

```go
func StartPersistence(driver string) (books BooksPersistor, err error){
  switch driver {
  case "postgres":
    books = initPostgres()
  default:
    err = errors.New("Invalid driver")
  }
  return
}
```

This "model" enable a more "organized" way to define your persistence module, enabling also a seamless multi-db support. 
This is a initial proposal to an extended model for persistence in go. Please leave a comment, I'm curious about your opinion. 