# Leto

[![Gem Version](https://badge.fury.io/rb/leto.svg)](http://badge.fury.io/rb/leto)
[![Build Status](https://github.com/jaynetics/leto/actions/workflows/tests.yml/badge.svg)](https://github.com/jaynetics/leto/actions)
[![Coverage](https://codecov.io/gh/jaynetics/leto/branch/main/graph/badge.svg?token=0993K9I8VC)](https://codecov.io/gh/jaynetics/leto)

Leto is a generic object traverser for Ruby (named after the Greek [childbearing goddess Leto](https://www.theoi.com/Titan/TitanisLeto.html)).

It takes an object and recursively yields:

- the given object
- instance variables, class variables, constants
- any object attributes, such as Array members, that are built into Ruby ([full list](#built-ins))

This makes stuff like deep-freezing fairly easy to implement:

```ruby
my_object = [ { a: ['b', 'c'..'d'] } ]

Leto.call(my_object, &:freeze)

my_object.frozen? # => true
my_object[0].frozen? # => true
my_object[0][:a][1].begin.frozen? # => true
```

Note: the slightly smarter `Leto.deep_freeze` is one of the [included utility methods](#included-utils).

## Usage

Basic example:

```ruby
object = [{ a: ['b', 'c'..'d'] }]

Leto.call(object) { |el| puts "#{el.class}: #{el}" }
```

This prints:

```
Array: [{a: ["b", "c".."d"]}]
Hash: {a: ["b", "c".."d"]}
Symbol: a
Array: ["b", "c".."d"]
String: b
Range: c..d
String: c
String: d
```

Calls without a block return an `Enumerator`:

```ruby
Leto.call(object).to_a
# => [[{:a=>["b", ["c".."d"]]}], {:a=>["b", ["c".."d"]]}, :a, ...]
```

`Leto.trace` behaves like `.call`, but also yields each (sub-)object's `Path`:

```ruby
Leto.trace(object) { |el, path| puts "#{el.inspect.ljust(23)} @#{path}" }
```

This prints:

```
[{:a=>["b", "c".."d"]}] @#<Leto::Path [{:a=>["b", "c".."d"]}]>
{:a=>["b", "c".."d"]}   @#<Leto::Path [{:a=>["b", "c".."d"]}][0]>
:a                      @#<Leto::Path [{:a=>["b", "c".."d"]}][0].keys[0]>
["b", "c".."d"]         @#<Leto::Path [{:a=>["b", "c".."d"]}][0][:a]>
"b"                     @#<Leto::Path [{:a=>["b", "c".."d"]}][0][:a][0]>
"c".."d"                @#<Leto::Path [{:a=>["b", "c".."d"]}][0][:a][1]>
"c"                     @#<Leto::Path [{:a=>["b", "c".."d"]}][0][:a][1].begin>
"d"                     @#<Leto::Path [{:a=>["b", "c".."d"]}][0][:a][1].end>
```

Paths can be looked up with `Leto::Path#resolve` or `Leto.dig`:

```ruby
path = Leto.trace(object).map { |_el, path| path }.last # => #<Leto::Path...>
path.resolve # => "d"
Leto.dig(object, path) # => "d"
```

Arrays of Arrays, where the inner ones contain method names and arguments, are valid paths:

```ruby
Leto.dig(object, [[:[], 0], [:[], :a], [:[], 1], [:end]]) # => "d"
```

<a name='built-ins'></a>

### Supported built-in classes and attributes

The following classes are built into Ruby and some of their attributes are not exposed as regular instance variables. Leto handles these explicitly.

- `Complex` objects' real and imaginary parts
- [`Data`](https://docs.ruby-lang.org/en/3.2/Data.html) members
- `Enumerable` members
- `Exception` messages, backtraces, causes, and various subclass fields
- `Hash` keys, values, defaults, and default_procs
- `Range` begins and ends
- `Rational` numerators and denominators
- `Set` members (including for [native Sets on Ruby >= 4.0](https://bugs.ruby-lang.org/issues/21216))
- `Struct` and `OpenStruct` members
- `Time` zones, including custom timezone objects

<a name='included-utils'></a>

### Included utility methods

- [`Leto.deep_freeze(obj)`](https://github.com/search?q=deep_freeze+repo%3Ajaynetics%2Fleto+path%3Alib%2Fleto%2Futils.rb&type=code)
  - similar to the version above, but avoids freezing Modules and unfreezables
  - similar to [`Ractor.make_shareable`](https://docs.ruby-lang.org/en/4.0/Ractor.html#method-c-make_shareable)
- [`Leto.deep_print(obj)`](https://github.com/search?q=deep_print+repo%3Ajaynetics%2Fleto+path%3Alib%2Fleto%2Futils.rb&type=code)
  - for debugging - prints more information than `pretty_print` does by default
- [`Leto.deep_eql?(obj1, obj2)`](https://github.com/search?q=deep_eql+repo%3Ajaynetics%2Fleto+path%3Alib%2Fleto%2Futils.rb&type=code)
  - stricter version of `#eql?` that takes all ivars into consideration
- [`Leto.deep_dup(obj)`](https://github.com/search?q=deep_dup+repo%3Ajaynetics%2Fleto+path%3Alib%2Fleto%2Futils.rb&type=code)
  - more thorough than [`active_support`](https://www.rubydoc.info/search/gems/activesupport?q=deep_dup) or [`deep_dup`](https://github.com/ollie/deep_dup) gems, e.g. dups ivars
  - similar to [`Ractor.make_shareable(obj, copy: true)`](https://docs.ruby-lang.org/en/4.0/Ractor.html#method-c-make_shareable), but doesn't freeze
- [`Leto.shared_mutable_state?(obj1, obj2, ...)`](https://github.com/search?q=shared_mutable_state+repo%3Ajaynetics%2Fleto+path%3Alib%2Fleto%2Futils.rb&type=code)
  - useful for debugging or verifying that a `#dup` implementation is sane
- [`Leto.shared_mutables(obj1, obj2)`](https://github.com/search?q=shared_mutables+repo%3Ajaynetics%2Fleto+path%3Alib%2Fleto%2Futils.rb&type=code)
  - useful for debugging or verifying that a `#dup` implementation is sane
- [`Leto.shared_objects(obj1, obj2)`](https://github.com/search?q=shared_objects+repo%3Ajaynetics%2Fleto+path%3Alib%2Fleto%2Futils.rb&type=code)
  - returns all objects shared by `obj1` and `obj2`, whether mutable or not

To make a shareable copy while leaving the original mutable:

```ruby
copy = Leto.deep_freeze(object, shareable: true, copy: true)
```

Duplicating a Proc does not duplicate its captured environment. Shareable freezing
uses Ruby's rules for Procs, Methods, and other native objects, which vary between
Ruby versions.

Shareable freezing leaves Classes and Modules as they are, following Ractor's
rules. `include_modules: true` applies to regular deep freezing.

## Benchmarks

```
    Leto.deep_freeze:     8762.1 i/s
 IceNine.deep_freeze:     7390.3 i/s - 1.19x  (± 0.00) slower
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/jaynetics/leto.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
