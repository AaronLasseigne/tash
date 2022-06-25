# [Tash][]

Tash is a hash that allows for transformation of its keys.
A transformation block is given to change the key.
Keys can be looked up with any value that transforms into the same key.
This means a hash can be string/symbol insensitive, case insensitive, can convert camel case JSON keys to snake case Ruby keys, or anything else based on the block you provide.

[![Version](https://img.shields.io/gem/v/tash.svg?style=flat-square)](https://rubygems.org/gems/tash)
[![Test](https://img.shields.io/github/workflow/status/AaronLasseigne/tash/Test?label=Test&style=flat-square)](https://github.com/AaronLasseigne/tash/actions?query=workflow%3ATest)

---

## Installation

Add it to your Gemfile:

``` rb
gem 'tash', '~> 0.1.0'
```

Or install it manually:

``` sh
$ gem install tash --version '~> 0.1.0'
```

This project uses [Semantic Versioning][].
Check out [GitHub releases][] for a detailed list of changes.

## Usage

Let's say that you wanted to have a hash where the keys are accessible as strings or symbols (i.e. `ActiveSupport::HashWithIndifferentAccess`).

``` rb
t = Tash[one: 1, two: 2, &:to_s]
# => {"one"=>1, "two"=>2}

t[:one]
# => 1

t['one']
# => 1

t[:three] = 9 # oops
# => 9

t['three'] = 3
# => 3

t[:three]
# => 3

t['three']
# => 3
```

Lets say that you recieve a series of camel case JSON keys from an API call but want to access the information with Rubys typical snake case style and symbolized.

``` rb
json = { "firstName" => "Adam", "lastName" => "DeCobray" }

t = Tash[json] do |key|
  key
    .to_s
    .gsub(/(?<!\A)([A-Z])/, '_\1')
    .downcase
    .to_sym
end

t[:first_name]
# => "Adam"

t['firstName']
# => "Adam"
```

This also works with pattern matching:

``` rb
t = Tash[ONE: 1, MORE: 200, &:downcase]

case t
in { One: 1, More: more }
  more
else
  nil
end
# => 200
```

Tash implements `to_hash` for implicit hash conversion making it usable nearly everywhere you use a hash.

Tash has every instance method Hash has except for `transform_keys` and `transform_keys!`.

[API Documentation][]

## Contributing

If you want to contribute to Tash, please read [our contribution guidelines][].
A [complete list of contributors][] is available on GitHub.

## License

Tash is licensed under [the MIT License][].

[Tash]: https://github.com/AaronLasseigne/tash
[semantic versioning]: http://semver.org/spec/v2.0.0.html
[GitHub releases]: https://github.com/AaronLasseigne/tash/releases
[API Documentation]: http://rubydoc.info/github/AaronLasseigne/tash
[our contribution guidelines]: CONTRIBUTING.md
[complete list of contributors]: https://github.com/AaronLasseigne/tash/graphs/contributors
[the mit license]: LICENSE.txt
