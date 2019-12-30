module Specinfra
  module Helper
    module Docker
      def self.included(klass)
#         require 'docker' unless Object.const_defined?("::Docker")
        raise 'mruby-specinfra does not support dynamic require'
      rescue StandardError
        fail "Docker client library is not available. Try installing `docker-api' gem."
      end
    end
  end
end
