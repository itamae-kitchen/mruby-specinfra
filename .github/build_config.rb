MRuby::Build.new do |conf|
  toolchain :gcc
  conf.gembox 'default'
  conf.gem '../../mruby-specinfra'
  conf.enable_test
end
