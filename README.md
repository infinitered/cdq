
# Streamlined Core Data for RubyMotion

Core Data Query (CDQ) is a library to help you manage your Core Data stack
while using RubyMotion.  It uses a data model file, which you can generate in
XCode, or you can use [ruby-xcdm](https://github.com/infinitered/ruby-xcdm).
CDQ aims to streamline the process of getting you up and running Core Data, while
avoiding too much abstraction or method pollution on top of the SDK.  

## Why use a static Data Model?

By using a real data model file that gets compiled and included in your bundle,
you can take advantage of automatic migration, which simplifies managing your
schema as it grows.  

## Setting up your stack

You will need a data model file.  If you've created one in XCode, copy it to
your resources file and make sure it's named the same as your RubyMotion
project.  If you're using ruby-xcdm (which I highly recommend) then it will
create the datamodel file automatically and put it in the right place.  

Now include the setup code:

```ruby
class AppDelegate
  include CDQ

  def application(application, didFinishLaunchingWithOptions:launchOptions)
    cdq.setup
    true
  end
end

class TopLevel
  include CDQ
end
```

That's literally all you really need to do.  You can create specific
implementation classes for your entities if you want, but there's no need.  You
can start running queries on the console or in your code right away.  

## Creating new objects

CDQ maintains a stack of NSManagedObjectContexts for you, and any create
operations will insert new, unsaved objects into the context currently on top
of the stack.  `cdq.save` will save the whole stack, including correctly using
private threads if appropriate.

```ruby
cdq('Author').create(name: "Le Guin", publish_count: 150, first_published: 1970)
cdq('Author').create(name: "Shakespeare", publish_count: 400, first_published: 1550)
cdq('Author').create(name: "Blake", publish_count: 100, first_published: 1778)
cdq.save

```

## Queries

A quick aside about queries in Core Data.  You should avoid them whenever
possible in your production code.  Core data is designed to work efficiently
when you hang on to references to specific objects and use them as you would
any in-memory object, letting Core Data handle your memory usage for you.  If
you're coming from a server-side rails background, this can be pretty hard to
get used to, but this is a very different environment.  So if you find yourself
running queries that only return a single object, consider rearchitecting.
That said, queries are sometimes necessary, and it's very handy to be able to
use them easily when debugging from the console, so here you go:

```ruby

# Simple Queries
cdq('Author').where(:name).eq('Shakespeare') 
cdq('Author').where(:publish_count).gt(10)

# sort, limit, and offset
cdq('Author').sort_by(:created_at).limit(1).offset(10)

# Compound queries
cdq('Author').where(:name).eq('Blake').and(:first_published).le(Time.local(1700))

# Multiple comparisons against the same attribute
cdq('Author').where(:created_at).ge(yesterday).and.lt(today)

```

## Named Scopes

You can save up partially-constructed queries for later use using named scopes, even
combining them seamlessly with other queries or other named scopes:

```ruby

cdq('Author').scope :a_authors, cdq(:name).begins_with('A')
cdq('Author').scope :prolific, cdq(:publish_count).gt(99)

cdq('Author').prolific.a_authors.limit(5)

```

Note: strings and symbols are NOT interchangeable. `cdq('Entity')` begins gives you a 
query generator for the named entity, but `cdq(:attribute)` starts a predicate for the
given attribute.

## Dedicated Models

If you're using CDQ in a brand new project, you'll probably want to use
dedicated model classes for your entities.  It will enable the usual
class-level customization of your model objects, and also a somewhat more
familiar-looking and natural syntax for queries and scopes:

```ruby
class Author < CDQManagedOjbect
  scope :a_authors, cdq(:name).begins_with('A')
  scope :prolific, cdq(:publish_count).gt(99)
end
```

Now you can change the queries above to:

```ruby
Author.where(:name).eq('Shakespeare') 
Author.where(:publish_count).gt(10)
Author.where(:name).eq('Blake').and(:first_published).le(Time.local(1700))
Author.where(:created_at).ge(yesterday).and.lt(today)
Author.prolific.a_authors.limit(5)
```

Anything you can do with `cdq('Author')` you can now do with just `Author`. 


