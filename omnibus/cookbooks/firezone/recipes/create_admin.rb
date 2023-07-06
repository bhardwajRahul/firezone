# frozen_string_literal: true

# Cookbook:: firezone
# Recipe:: create_admin
#
# Copyright:: 2014 Chef Software, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

include_recipe 'firezone::config'

execute 'create_admin' do
  command 'bin/firezone eval "FzHttp.Release.create_admin_user"'
  cwd node['firezone']['app_directory']
  environment(Firezone::Config.app_env(node))
  user node['firezone']['user']
end

log 'admin_created' do
  external_url =
    node['firezone']['external_url'] || "https://#{node['firezone']['fqdn'] || node['fqdn'] || node['hostname']}"

  msg = <<~MSG
    =================================================================================

    Firezone user created! Save this information because it will NOT be shown again.

    Use these credentials to sign in to the web UI at #{external_url}.

    Email:    #{node['firezone']['admin_email']}
    Password: #{node['firezone']['default_admin_password']}

    =================================================================================
  MSG

  message msg
  level :info # info and below are not shown by default
end
