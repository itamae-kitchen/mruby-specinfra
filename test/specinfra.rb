assert('Specinfra host_inventory') do
  backend = Specinfra::Backend::Exec.new(shell: '/bin/sh')
  assert_kind_of Specinfra::HostInventory, backend.host_inventory
end

assert('Specinfra get_command') do
  backend = Specinfra::Backend::Exec.new(shell: '/bin/sh')
  assert_equal 'id -u root', backend.command.get(:get_user_uid, 'root')
end
