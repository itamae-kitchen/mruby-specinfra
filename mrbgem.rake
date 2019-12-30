MRuby::Gem::Specification.new('mruby-specinfra') do |spec|
  spec.license = 'MIT'
  spec.authors = [
    'Gosuke Miyashita',
    'Takashi Kokubun',
  ]
  spec.add_dependency 'mruby-array-ext'
  spec.add_dependency 'mruby-metaprog'
  spec.add_dependency 'mruby-onig-regexp'
  spec.add_dependency 'mruby-open3'
  spec.add_dependency 'mruby-shellwords'
end
