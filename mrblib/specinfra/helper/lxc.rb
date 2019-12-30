module Specinfra
  module Helper
    module Lxc
      def self.included(klass)
#         require 'lxc/extra' unless Object.const_defined?("::LXC::Extra")
      rescue LoadError
        fail "LXC client library is not available. Try installing `ruby-lxc' gem."
      end
    end
  end
end
