[![Build Status](https://travis-ci.org/afred/interloper.svg?branch=master)](https://travis-ci.org/afred/interloper)

# Interloper

Interloper adds _before_ and _after_ callback hooks to methods on POROs (plain old Ruby objects).

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'interloper'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install interloper

## Usage

To add `before` and `after` callbacks to a method:
```ruby
require 'interloper'

class Foo
  include Interloper

  before(:do_something) { puts "do something before" }
  before(:do_something) { puts "do something else before" }
  after(:do_something) { puts "do something after" }
  after(:do_something) { puts "do something else after" }

  def do_something
    puts "doing it"
  end
end

Foo.new.do_something
```
**Output:**
```
do something before
do something else before
doing it
do something after
do something else after
=> nil
```


Callbacks will receive the same arguments as the method being called.
```ruby
require 'interloper'
class Foo
  include Interloper

  before(:do_something) do |x|
    puts "do something before, with #{x}"
  end

  def do_something(something)
    puts "doing it with #{something}"
  end
end

Foo.new.do_something("grace and style")
```
Output:
```
do something before, with grace and style
doing it with grace and style
 => nil 
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/Andrew Myers/interloper.

