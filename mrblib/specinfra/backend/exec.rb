module Specinfra
  module Backend
    class Exec < Base
      def run_command(cmd, opts={})
        stdout, stderr, status = Open3.capture3(@config[:shell], '-c', cmd)

        if @example
          @example.metadata[:command] = cmd
          @example.metadata[:stdout]  = stdout
        end

        CommandResult.new :stdout => stdout, :stderr => stderr, :exit_status => status
      end

      def send_file(from, to)
        FileUtils.cp(from, to)
      end

      def send_directory(from, to)
        FileUtils.cp_r(from, to)
      end

      def build_command(cmd)
        shell = get_config(:shell) || '/bin/sh'
        cmd = cmd.shelljoin if cmd.is_a?(Array)
        shell = shell.shellescape

        if get_config(:interactive_shell)
          shell << " -i"
        end

        if get_config(:login_shell)
          shell << " -l"
        end

        cmd = "#{shell} -c #{cmd.to_s.shellescape}"

        path = get_config(:path)
        if path
          cmd = %Q{env PATH="#{path}" #{cmd}}
        end

        cmd
      end
    end
  end
end
