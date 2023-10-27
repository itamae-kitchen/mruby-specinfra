#!/usr/bin/env ruby
require 'erb'
require 'fileutils'
require 'shellwords'
require 'tmpdir'

# Usage:
#   1. Update SPECINFRA_VERSION
#   2. Run ./update_specinfra.rb
SPECINFRA_REPO    = 'mizzy/specinfra'
SPECINFRA_VERSION = 'v2.87.0'

module GitHubFetcher
  def self.fetch(repo, tag:, path:)
    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        url = "https://github.com/#{repo}/archive/#{tag}.tar.gz"
        system("curl -L --fail --retry 3 --retry-delay 1 #{url} -o - | tar zxf -")
        FileUtils.mv("#{File.basename(repo)}-#{tag.sub(/\Av/, '')}", path)
      end
    end
  end
end

# Generate mrblib from lib
class MRubySpecinfraBuilder
  # Upper rules match first.
  RENAME_RULES = {
    %r[\A/specinfra/backend/base\.rb\z]        => '/specinfra/backend/0_base.rb',           # seen by specinfra/backend/exec.rb
    %r[\A/specinfra/backend/exec\.rb\z]        => '/specinfra/backend/1_exec.rb',           # seen by specinfra/backend/powershell.rb
    %r[\A/specinfra/backend/powershell/]       => '/specinfra/backend/2_powershell/',       # seen by specinfra/backend/cmd.rb
    %r[\A/specinfra/command/module/service/]   => '/specinfra/command/0_module/0_service/', # seen by specinfra/command/module/openrc.rb
    %r[\A/specinfra/command/module(/|\.rb\z)]  => '/specinfra/command/0_module\1',          # seen by specinfra/command/base/service.rb
    %r[\A/specinfra/command/base(/|\.rb\z)]    => '/specinfra/command/1_base\1',            # seen by specinfra/command/linux/base.rb, specinfra/command/solaris/base.rb
    %r[\A/specinfra/command/solaris(/|\.rb\z)] => '/specinfra/command/2_solaris\1',         # seen by specinfra/command/smartos/base.rb
    %r[\A/specinfra/command/linux(/|\.rb\z)]   => '/specinfra/command/2_linux\1',           # seen by specinfra/command/debian/base.rb, specinfra/command/redhat/base.rb, specinfra/command/suse/base.rb, ...
    %r[\A/specinfra/command/suse(/|\.rb\z)]    => '/specinfra/command/3_suse\1',            # seen by specinfra/command/opensuse/base.rb
    %r[\A/specinfra/command/debian(/|\.rb\z)]  => '/specinfra/command/3_debian\1',          # seen by specinfra/command/ubuntu/base.rb
    %r[\A/specinfra/command/redhat(/|\.rb\z)]  => '/specinfra/command/3_redhat\1',          # seen by specinfra/command/fedora/base.rb
    %r[\A/specinfra/command/ubuntu(/|\.rb\z)]  => '/specinfra/command/4_ubuntu\1',          # seen by specinfra/command/elementary/base.rb
    %r[\A/specinfra/command/fedora(/|\.rb\z)]  => '/specinfra/command/4_fedora\1',          # seen by specinfra/command/eos/base.rb
  }

  def initialize(lib:, mrblib:)
    @lib = lib
    @mrblib = mrblib
  end

  def build
    Dir.glob(File.join(@lib, '**/*.rb')).sort.each do |src_fullpath|
      src_path = src_fullpath.sub(/\A#{Regexp.escape(@lib)}/, '')
      dest_path = src_path.dup
      if rule = RENAME_RULES.find { |from, _to| dest_path.match?(from) }
        dest_path.sub!(rule.first, rule.last)
      end
      dest_fullpath = File.join(@mrblib, dest_path)

      FileUtils.mkdir_p(File.dirname(dest_fullpath))
      FileUtils.cp(src_fullpath, dest_fullpath)

      src = File.read(dest_fullpath)
      patch_source!(src, path: src_path)
      File.write(dest_fullpath, src)
    end
  end

  private

  def patch_source!(src, path:)
    # Not using mruby-require for single binary build. Require order is resolved by RENAME_RULES.
    src.gsub!(/^ *require ["'][^"']+["']( .+)?$/, '# \0')

    # No `defined?` in mruby.
    src.gsub!(/ defined\?\(([^)]+)\)/, ' Object.const_defined?("\1")')

    # `LoadError` doesn't exist in mruby. Because we suppress `require`, everything could happen.
    src.gsub!(/^( *)rescue LoadError/, "\\1  raise 'mruby-specinfra does not support dynamic require'\n\\1rescue StandardError")

    case path
    when '/specinfra.rb'
      # 'include' is not defined. Besides we don't need the top-level include feature.
      src.gsub!(/^include .+$/, '# \0')
    when '/specinfra/backend/exec.rb'
      # Specinfra::Backend::Exec#spawn_command uses Thread. mruby-thread had issues and we're just using mruby-open3 instead.
      src.gsub!(
        /^( +)def spawn_command\(cmd\)$/,
        "\\1def spawn_command(cmd)\n" +
        "\\1  out, err, result = Open3.capture3(@config[:shell], '-c', cmd)\n" + # workaround. Just `Open3.capture3(cmd)` hangs for some reason
        "\\1  return out, err, result.exitstatus\n" +
        "\\1end\n" +
        "\n" +
        "\\1def __unused_original_spawn_method(cmd)"
      )
    when '/specinfra/ext/class.rb'
      # Special code generation for missing ObjectSpace
      src.replace(generate_class_ext)
    end
  end

  def generate_class_ext
    classes = `find #{@lib.shellescape} -type f -exec grep "\\.subclasses" {} \\;`.each_line.map do |line|
      line.sub(/\A */, '').sub(/\.subclasses.*\n\z/, '')
    end.sort

    subclasses = {}
    classes.each do |klass|
      subclasses[klass] = `find #{@lib.shellescape} -type f -exec grep "#{klass}" {} \\;`
        .scan(/#{klass}::[^:\n ]+/).sort.uniq
    end

    ERB.new(<<~'RUBY', trim_mode: '%').result(binding)
      class Class
        def subclasses
          case self.to_s
      % classes.each do |klass|
          when "<%= klass %>"
            [
      %   subclasses.fetch(klass).each do |subclass|
              <%= subclass %>,
      %   end
            ]
      % end
          else
            raise "#{self} is not supposed by mruby-specinfra Class#subclasses"
          end
        end
      end
    RUBY
  end
end

FileUtils.rm_rf(specinfra_dir = File.expand_path('./specinfra', __dir__))
GitHubFetcher.fetch(SPECINFRA_REPO, tag: SPECINFRA_VERSION, path: specinfra_dir)

FileUtils.rm_rf(mrblib_dir = File.expand_path('./mrblib', __dir__))
MRubySpecinfraBuilder.new(
  lib: File.join(specinfra_dir, 'lib'),
  mrblib: mrblib_dir,
).build
