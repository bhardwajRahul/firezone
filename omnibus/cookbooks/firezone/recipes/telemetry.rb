# frozen_string_literal: true

# Cookbook:: firezone
# Recipe:: telemetry
#
# Copyright:: 2022, Firezone, All Rights Reserved.

# Configure telemetry app-wide.

include_recipe 'firezone::config'

disable_telemetry = "#{node['firezone']['install_directory']}/.disable-telemetry"

if node['firezone']['telemetry']['enabled'] == false
  file disable_telemetry do
    mode '0644'
    user node['firezone']['user']
    group node['firezone']['group']
  end
else
  file disable_telemetry do
    action :delete
  end
end
