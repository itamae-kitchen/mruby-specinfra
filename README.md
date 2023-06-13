# mruby-specinfra [![Build Status](https://travis-ci.org/itamae-kitchen/mruby-specinfra.svg?branch=master)](https://travis-ci.org/itamae-kitchen/mruby-specinfra)

[Specinfra](https://github.com/mizzy/specinfra) for mruby.

## Installation

```ruby
MRuby::Build.new do |conf|
  conf.gem mgem: 'mruby-specinfra'
end
```

## Usage

See [mitamae](https://github.com/itamae-kitchen/mitamae).

## Contributing

mruby-specinfra copies changes from upstream [mizzy/specinfra](https://github.com/mizzy/specinfra)
using [update\_specinfra.rb](./update_specinfra.rb).

Please submit a patch to the upstream first when you need something in mruby-specinfra.

## License

[MIT License](./LICENSE)
