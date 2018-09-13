module Specinfra
  module Helper
    class DetectOs
      class Termux < Specinfra::Helper::DetectOs
        def detect
          if (termux_info = run_command('termux-info')) && termux_info.success?
            distro = 'termux'
            release = nil
            { family: distro, release: release }
          end
        end
      end
    end
  end
end
