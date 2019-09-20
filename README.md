
# Streamlined Core Data for RubyMotion

Core Data Query (CDQ) is a library to help you manage your Core Data stack
while using RubyMotion.  It uses a data model file, which you can generate in
XCode, or you can use [ruby-xcdm](https://github.com/infinitered/ruby-xcdm).

[![Build Status](https://travis-ci.org/infinitered/cdq.png?branch=master)](https://travis-ci.org/infinitered/cdq)
[![Gem Version](https://badge.fury.io/rb/cdq.png)](http://badge.fury.io/rb/cdq)

CDQ is maintained by [Infinite Red](http://infinite.red), a web and mobile development company based in Portland, OR and San Francisco, CA.

## Get Started
1. [Introducing CDQ](#introducingCDQ)
2. [Greenfield Quick Start Tutorial](https://github.com/infinitered/cdq/wiki/Greenfield-Quick-Start)
3. [Cheat Sheet](https://github.com/infinitered/cdq/wiki/CDQ-Cheat-Sheet)
4. [API docs](http://rubydoc.info/github/infinitered/cdq)

## Introducing CDQ

CDQ began its life as a fork of
[MotionData](https://github.com/alloy/MotionData), but it became obvious I
wanted to take things in a different direction, so I cut loose and ended up
rewriting almost everything.  If you pay attention, you can still find the
genetic traces, so thanks to @alloy for sharing his work and letting me learn
so much.

CDQ aims to streamline the process of getting you up and running Core Data, while
avoiding too much abstraction or method pollution on top of the SDK.  While it
borrows many ideas from ActiveRecord (especially AREL), it is designed to
harmonize with Core Data's way of doing things first.

I am actively developing and improving CDQ (updated February 2015) so if you have
trouble or find a bug, please open a ticket!

### Why use a static Data Model?

By using a real data model file that gets compiled and included in your bundle,
you can take advantage of automatic migration, which simplifies managing your
schema as it grows, if you can follow a few [simple rules](https://developer.apple.com/library/ios/documentation/cocoa/conceptual/CoreDataVersioning/Articles/vmLightweightMigration.html#//apple_ref/doc/uid/TP40004399-CH4-SW2).

## Installing

```bash
$ gem install cdq
$ motion create my_app # if needed
$ cd my_app
$ cdq init
```

This way assumes you want to use ruby-xcdm.  Run `cdq -h` for list of more generators.

### Using Bundler:

```ruby
gem 'cdq'
```

If you want to see bleeding-edge changes, point Bundler at the git repo:

```ruby
gem 'cdq', git: 'git://github.com/infinitered/cdq.git'
```

## Setting up your stack

You will need a data model file.  If you've created one in XCode, move or copy
it to your resources file and make sure it's named the same as your RubyMotion
project.  If you're using `ruby-xcdm` (which I highly recommend) then it will
create the datamodel file automatically and put it in the right place.

Now include the setup code in your `app_delegate.rb` file:

```ruby
class AppDelegate
  include CDQ

  def application(application, didFinishLaunchingWithOptions:launchOptions)
    cdq.setup
    true
  end
end
```

That's it!  You can create specific implementation classes for your entities if
you want, but it's not required.  You can start running queries on the console or
in your code right away.

## Schema

The best way to use CDQ is together with ruby-xcdm, which is installed as a
dependency.  For the full docs, see its [github page](http://github.com/infinitered/ruby-xcdm),
but here's a taste.  Schema files are found in the "schemas" directory within your
app root, and they are versioned for automatic migrations, and this is what they look like:

```ruby
  schema "0001 initial" do

    entity "Article" do
      string    :body,        optional: false
      integer32 :length
      boolean   :published,   default: false
      datetime  :publishedAt, default: false
      string    :title,       optional: false

      belongs_to :author
    end

    entity "Author" do
      float :fee
      string :name, optional: false

      # Deleting an author will delete all associated articles
      has_many :articles, deletionRule: "Cascade"
    end

  end
```

Ruby-xcdm translates these files straight into the XML format that Xcode uses for datamodels.

### Boolean Values

Since CoreData stores boolean values as an `NSNumber`, cdq provides helper
methods to allow you to get the boolean value of the property. Take the `Article`
model from above with the `boolean`:`published`. If you call `published` directly
you'll get the `NSNumber` `0` or `1`. If you call `published?` you'll get a
boolean `true` or `false`

```ruby
article_1 = Article.create(published: true)
article_2 = Article.create(published: false)

article_1.published # => 1
article_2.published # => 0

article_1.published? # => true
article_2.published? # => false
```

## Context Management

Managing NSManagedObjectContext objects in Core Data can be tricky, especially
if you are trying to take advantage of nested contexts for better threading
behavior.  One of the best parts of CDQ is that it handles contexts for you
relatively seamlessly.  If you have a simple app, you may never need to worry
about contexts at all.

### Nested Contexts

For a great discussion of why you might want to use nested contexts, see [here](http://www.cocoanetics.com/2012/07/multi-context-coredata/).

CDQ maintains a stack of contexts (one stack per thread), and by default, all
operations on objects use the topmost context.  You just call `cdq.save`
and it saves the whole stack.  Or you can get a list of all the contexts in
order with `cdq.contexts.all` and do more precise work.

To access the `cdq` object from a class method inside a class that is not a `CDQManagedObject`
subclass, make sure to include the `CDQ` module in your class like this:

```ruby
class MyClass
  class << self
    include CDQ

    def my_class_method
      # Do something
      cdq.save
    end
  end
end

# Elsewhere
MyClass.my_class_method
```

Settings things up the way you want is easy.  Here's how you'd set it up for asynchronous
saves:

```ruby
  cdq.contexts.push(:root)
  cdq.contexts.push(:main)
```

This pushes a private queue context onto the bottom of the stack, then a main queue context on top of it.
Since the main queue is on top, all your data operations will use that.  `cdq.save` then saves the
main context, and schedules a save on the root context.

In addition, since these two contexts are globally important, it makes them available at `cdq.contexts.main` and
`cdq.contexts.root`.

### Temporary Contexts

From time to time, you may need to use a temporary context.  For example, on
importing a large amount of data from the network, it's best to process and
load into a temporary context (possibly in a background thread) and then move
all the data over to your main context all at once.  CDQ makes that easy too:

```ruby
  cdq.background do

    # Your work here

    cdq.save
  end
```

## Object Lifecycle

### Creating
```ruby
  Author.create(name: "Le Guin", publish_count: 150, first_published: 1970)
  Author.create(name: "Shakespeare", publish_count: 400, first_published: 1550)
  Author.create(name: "Blake", publish_count: 100, first_published: 1778)
  cdq.save
```

CDQ will automatically set the object's property `created_at` to `Time.now` if it exists. If you want to use this ActiveRecord-like automatic attribute, make sure to add `datetime :created_at` to your schema's model definition.

### Reading

```ruby
  author = Author.create(name: "Le Guin", publish_count: 150, first_published: 1970)
  author.name # => "Le Guin"
  author.publish_count # => 150
  author.attributes # => { "name" => "Le Guin", "publish_count" => 150, "first_published" => 1970 }
```

### Updating
```ruby
  author = Author.first
  author.name = "Ursula K. Le Guin"
  cdq.save
```

You can also update multiple attributes of a single object:

```ruby
  author = Author.first
  author.update(name: "Mark Twain", publish_count: 30, first_published: 1865)
  cdq.save
```

The update command will raise an `UnknownAttributeError` if you try and set an attribute that doesn't exist on the object so it's good practice to sanitize the data before you call `update`:

```ruby
  new_author_data = {
    name: "Mark Twain",
    publish_count: 30,
    first_published: 1865,
    some_attribute_that_doesnt_exist_on_author: "balderdash!"
  }  
  sanitized = new_author_data.keep_if{|k,_| Author.attribute_names.include?(k) }

  author = Author.first
  author.update(sanitized)
  cdq.save
```

**NOTE** Custom class methods will have to `include CDQ` in order to have access to the `cdq` object. If you're calling `cdq` from a class method, you also have to `extend CDQ`.

CDQ will automatically set the object's property `updated_at` to `Time.now` if it exists. If you want to use this ActiveRecord-like automatic attribute, make sure to add `datetime :updated_at` to your schema's model definition.

### Deleting
```ruby
  author = Author.first
  author.destroy
  cdq.save
```

## Queries

A quick aside about queries in Core Data.  You should avoid them whenever
possible in your production code.  Core Data is designed to work efficiently
when you hang on to references to specific objects and use them as you would
any in-memory object, letting Core Data handle your memory usage for you.  If
you're coming from a server-side rails background, this can be pretty hard to
get used to, but this is a very different environment.  So if you find yourself
running queries that only return a single object, consider rearchitecting.
That said, queries are sometimes the only solution, and it's very handy to be
able to use them easily when debugging from the console, or in unit tests.

All of these queries are infinitely daisy-chainable, and almost everything is
possible to do using only chained methods, no need to drop into NSPredicate format
strings unless you want to.

Here are some examples.  **See the [cheat sheet](https://github.com/infinitered/cdq/wiki/CDQ-Cheat-Sheet) for a complete list.**

### Conditions

```ruby
  Author.where(:name).eq('Shakespeare')
  Author.where(:publish_count).gt(10)
  Author.where(name: 'Shakespeare', publish_count: 15)
  Author.where("name LIKE %@", '*kesp*')
  Author.where("name LIKE %@", 'Shakespear?')
```

### Sorts, Limits and Offsets

```ruby
  Author.sort_by(:created_at).limit(1).offset(10)
  Author.sort_by(:created_at, order: :descending)
  Author.sort_by(:created_at, case_insensitive: true)
```

### Conjunctions

```ruby
  Author.where(:name).eq('Blake').and(:first_published).le(Time.local(1700))

  # Multiple comparisons against the same attribute
  Author.where(:created_at).ge(yesterday).and.lt(today)
```

#### Nested Conjunctions

```ruby
  Author.where(:name).contains("Emily").and(cdq(:pub_count).gt(100).or.lt(10))
```

### Calculations

```ruby
  Author.sum(:fee)
  Author.average(:fee)
  Author.min(:fee)
  Author.max(:fee)
  Author.where(:name).eq("Emily").sum(:fee)
```

### Fetching

Like ActiveRecord, CDQ will not run a fetch until you actually request specific
objects.  There are several methods for getting at the data:

 * `array`
 * `first`
 * `last`
 * `each`
 * `[]`
 * `map`
 * Anything else in `Enumerable`

## Dedicated Models

If you're using CDQ in a brand new project, you'll probably want to use
dedicated model classes for your entities.
familiar-looking and natural syntax for queries and scopes:

```ruby
  class Author < CDQManagedObject
  end
```

## Named Scopes

You can save up partially-constructed queries for later use using named scopes, even
combining them seamlessly with other queries or other named scopes:

```ruby
  class Author < CDQManagedObject
    scope :a_authors, where(:name).begins_with('A')
    scope :prolific, where(:publish_count).gt(99)
  end

  Author.prolific.a_authors.limit(5)
```

## Using CDQ with a pre-existing model

If you have an existing app that already manages its own data model, you can
still use CDQ, overriding its stack at any layer:

```ruby
cdq.setup(context: App.delegate.mainContext) # don't set up model or store coordinator
cdq.setup(store: App.delegate.persistentStoreCoordinator) # Don't set up model
cdq.setup(model: App.delegate.managedObjectModel) # Don't load model
```

You cannot use CDQManagedObject as a base class when overriding this way,
you'll need to use the master method, described below.  If you have an
existing model and want to use it with CDQManagedObject without changing its
name, You'll need to use a <tt>cdq.yml</tt> config file.  See
[CDQConfig](http://github.com/infinitered/cdq/tree/master/motion/cdq/config.rb).

### Working without model classes using the master method

If you need or want to work without using CDQManagedObject as your base class,
you can use the `cdq()`master method.  This is a "magic" method, like
`rmq()` in [RubyMotionQuery](http://github.com/infinitered/rmq) or
`$()` in jQuery, which will lift whatever you pass into it into the CDQ
universe. The method is available inside all UIResponder classes (so, views and
controllers) as well as in the console.  You can use it anywhere else by
including the model `CDQ` into your classes.  To use an entity without a
model class, just pass its name as a string into the master method, like so

```ruby
  cdq('Author').where(:name).eq('Shakespeare')
  cdq('Author').where(:publish_count).gt(10)
  cdq('Author').sort_by(:created_at).limit(1).offset(10)
```

Anything you can do with a model, you can also do with the master method, including
defining and using named scopes:

```ruby
  cdq('Author').scope :a_authors, cdq(:name).begins_with('A')
  cdq('Author').scope :prolific, cdq(:publish_count).gt(99)
```
> NOTE: strings and symbols are NOT interchangeable. `cdq('Entity')` gives you a
query generator for an entity, but `cdq(:attribute)` starts a predicate for an
attribute.

## Reserved model attributes

CDQ does some smart automatic attribute setting. If you add attributes `:created_at` and/or `:updated_at` to a model in your schema file, whenever a record is created or updated, these properties will be updated accordingly. Therefore, you can not define your own `:created_at` or `:updated_at` model attributes. These attributes must be of type `datetime`. Note that these attributes aren't set until you call `cdq.save`

Example:

```ruby
schema "0001 initial" do
  entity "Author" do
    string :name, optional: false

    datetime :created_at
    datetime :updated_at
  end
end
```

```ruby
a = Author.create(name: "Le Guin")
# Notice that the properties aren't set yet
#
# <Author: 0x1175f9540> (entity: Author; id: 0x117504810
# <x-coredata:///Author/tA4E22210-72CF-4272-BF2C-0C5C63A55B072> ; data: {
#     name: "Le Guin";
#     created_at: nil;
#     updated_at: nil;
# })

cdq.save

puts a # Original reference to created Author object
# <Author: 0x1175f9540> (entity: Author; id: 0x117504810
# <x-coredata:///Author/tA4E22210-72CF-4272-BF2C-0C5C63A55B072> ; data: {
#     name: "Le Guin";
#     created_at: 2015-08-19 20:44:40 +0000;
#     updated_at: 2015-08-19 20:44:40 +0000;
# })

a.name = "Some Other Guy"
puts a
# Note that nothing has changed except the name:
#
# <Author: 0x1175f9540> (entity: Author; id: 0x117504810
# <x-coredata:///Author/tA4E22210-72CF-4272-BF2C-0C5C63A55B072> ; data: {
#     name: "Some Other Guy";
#     created_at: 2015-08-19 20:44:40 +0000;
#     updated_at: 2015-08-19 20:44:40 +0000;
# })

cdq.save
puts a
# <Author: 0x1175f9540> (entity: Author; id: 0x117504810
# <x-coredata:///Author/tA4E22210-72CF-4272-BF2C-0C5C63A55B072> ; data: {
#     name: "Some Other Guy";
#     created_at: 2015-08-19 20:44:40 +0000;
#     updated_at: 2015-08-19 20:47:40 +0000;
# })
```

Also note that you should never use `object_id` as a model attribute as it will conflict with an internally generated property.

## iCloud

As of version 0.1.10, there is some experimental support for iCloud, written by
@katsuyoshi.  Please try it out and let us know how it's working for you.  To
enable, initialize like this:

```ruby
  cdq.stores.new(iCloud: true, container: "com.your.container.id")
```

You can also set up iCloud in your cdq.yml file.

## Documentation

* [API](http://rubydoc.info/github/infinitered/cdq)
* [Cheat Sheet](https://github.com/infinitered/cdq/wiki/CDQ-Cheat-Sheet)
* [Tutorial](https://github.com/infinitered/cdq/wiki/Greenfield-Quick-Start)

## Things that are currently missing

* There is no facility for custom migrations yet
* There are no explicit validations (but you can define them on your data model)
* Lifecycle Callbacks or Observers

## Tips

If you need, you could watch SQL statements by setting the following launch argument through `args` environment variable:

```
$ rake args='-com.apple.CoreData.SQLDebug 3'
```

`com.apple.CoreData.SQLDebug` takes a value between 1 and 3; the higher the value, the more verbose the output.

## Premium Support

[CDQ](https://github.com/infinitered/cdq), as an open source project, is free to use and always will be. [Infinite Red](https://infinite.red/) offers premium CDQ support and general mobile app design/development services. Email us at [hello@infinite.red](mailto:hello@infinite.red) to get in touch with us for more details.
