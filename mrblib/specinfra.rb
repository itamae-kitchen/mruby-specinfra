module Specinfra
  class << self
    def backend
      # TODO: Support more backends
      @backend ||= Backend::Exec.new
    end

    def command
      @command ||= Specinfra::CommandFactory.new
    end

    def configuration
      # FIXME: Properly import
      {}
    end
  end
end
