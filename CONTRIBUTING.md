# Contributing

The goal of Tash is to provide an interface that is as close to Hash as possible.
Anything that adds additional functionality to an existing method will likely be rejected since it might conflict with future changes to Hash.
Feel free to open a [discussion][] to talk through a new feature.

The goal of Tash is to be fast.
Any changes to speed it up are welcome.
Please provide [benchmark-ips][] comparisons of before an after.
An easy way to do this is to duplicate the method with a postfix of `_fast` and run it in a script or in `bin/console`.

Example:

``` rb
t = Tash[...]

Benchmark.ips do |x|
  x.report('some_method') do
    ...
  end

  x.report('some_method_fast') do
    ...
  end

  x.compare!
end
```

## Steps

1. [Fork][] the repo.
2. Add a breaking test for your change.
3. Make the tests pass.
4. Push your fork.
5. Submit a pull request.

## Code Style

Running the tests using `rake` (with no args) will also check for style issues in the code.
If you have a failure you cannot figure out push the PR and ask for help.

[fork]: https://github.com/AaronLasseigne/tash/fork
[discussion]: https://github.com/AaronLasseigne/tash/discussions/categories/ideas
[benchmark-ips]: https://rubygems.org/gems/benchmark-ips
