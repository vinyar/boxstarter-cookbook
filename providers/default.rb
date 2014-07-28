use_inline_resources

def whyrun_supported?
  true
end

action :run do
  require 'win32ole'

  if check_process_tree(Process.ppid, :CommandLine, 'boxstarter').nil?
    code = @new_resource.code || @new_resource.script
    password = @new_resource.password
    disable_reboots = @new_resource.disable_reboots

    chef_client_enabled = false
    if node.has_key?('chef_client') && node['chef_client']['init_style'] != 'none'
      chef_client_enabled = true
    end

    chef_client_command = "#{$0}.bat #{ARGV.join(' ')}"
    script_path = "#{node['boxstarter']['tmp_dir']}/package.ps1"

    template script_path do
    	source "package.erb"
      cookbook "boxstarter"
      variables({
        :code => code,
        :chef_client_enabled => chef_client_enabled,
        :chef_client_command => chef_client_command
      })
    end

    command_path = "#{node['boxstarter']['tmp_dir']}/boxstarter.ps1"
    template command_path do
      source "boxstarter_command.erb"
      cookbook "boxstarter"
      variables({
        :password => password,
        :chef_client_enabled => chef_client_enabled,
        :is_remote => !check_process_tree(Process.ppid, :Name, 'winrshost.exe').nil?,
        :temp_dir => node['boxstarter']['tmp_dir'],
        :disable_reboots => disable_reboots
      })
    end

    batch_path = "#{node['boxstarter']['tmp_dir']}/boxstarter.bat"
    template batch_path do
      source "ps_wrapper.erb"
      cookbook "boxstarter"
      variables({
        :command => "-file #{command_path}"
      })
    end

    ruby_block "Run Boxstarter Package" do
      block do
        cmd = Mixlib::ShellOut.new(batch_path)
        Chef::Log.debug(cmd)
        cmd.live_stream = STDOUT
        cmd.timeout = 7200
        cmd.run_command
      end
    end

    file command_path do
      action :delete
    end
    file batch_path do
      action :delete
    end
  end
end
