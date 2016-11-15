# mruby-specinfra   [![Build Status](https://travis-ci.org/k0kubun/mruby-specinfra.svg?branch=master)](https://travis-ci.org/k0kubun/mruby-specinfra)
Specinfra class
## install by mrbgems
- add conf.gem line to `build_config.rb`

```ruby
MRuby::Build.new do |conf|

    # ... (snip) ...

    conf.gem :github => 'k0kubun/mruby-specinfra'
end
```
## example
```ruby
p Specinfra.hi
#=> "hi!!"
t = Specinfra.new "hello"
p t.hello
#=> "hello"
p t.bye
#=> "hello bye"
```

## License
under the MIT License:
- see LICENSE file
