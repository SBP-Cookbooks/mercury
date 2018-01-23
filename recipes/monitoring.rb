#
# Cookbook:: mercury
# Recipe:: monitoring
#
# Copyright:: 2018, Schuberg Philis
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

if node.run_context.loaded_recipes.include?('sbp_sensu_checks::default')

  ruby = node['sbp_sensu_checks']['ruby_binary']
  sensu_path = node['sbp_sensu_checks']['sensu_bin_path']

  node.default['sbp_sensu_client']['checks']['check_mercury_globaldns']['enabled'] = true
  node.default['sbp_sensu_client']['checks']['check_mercury_globaldns']['interval'] = 300
  node.default['sbp_sensu_client']['checks']['check_mercury_globaldns']['timeout'] = 30
  node.default['sbp_sensu_client']['checks']['check_mercury_globaldns']['command'] = "#{node['mercury']['package']['bin']} --config-file #{node['mercury']['package']['config']} -check-glb"

  node.default['sbp_sensu_client']['checks']['check_mercury_backend']['enabled'] = true
  node.default['sbp_sensu_client']['checks']['check_mercury_backend']['interval'] = 300
  node.default['sbp_sensu_client']['checks']['check_mercury_backend']['timeout'] = 30
  node.default['sbp_sensu_client']['checks']['check_mercury_backend']['command'] = "#{node['mercury']['package']['bin']} --config-file #{node['mercury']['package']['config']} -check-backend"

end

if node.run_context.loaded_recipes.include?('sbp_nrpe_wrapper::default')

  node.default['nagios']['nrpe_commands']['check_mercury_globaldns']['interval'] = 300
  node.default['nagios']['nrpe_commands']['check_mercury_globaldns']['timeout'] = 30
  node.default['nagios']['nrpe_commands']['check_mercury_globaldns']['command'] = "#{node['mercury']['package']['bin']} --config-file #{node['mercury']['package']['config']} -check-glb"

  node.default['nagios']['nrpe_commands']['check_mercury_backend']['interval'] = 300
  node.default['nagios']['nrpe_commands']['check_mercury_backend']['timeout'] = 30
  node.default['nagios']['nrpe_commands']['check_mercury_backend']['command'] = "#{node['mercury']['package']['bin']} --config-file #{node['mercury']['package']['config']} -check-backend"

  node.default['nagios']['nrpe_commands']['check_mercury_backend']['interval'] = 300
  node.default['nagios']['nrpe_commands']['check_mercury_backend']['timeout'] = 30
  node.default['nagios']['nrpe_commands']['check_mercury_backend']['command'] = "#{node['nrpe']['sbp_plugin_dir']}/check_proc.pl -f -n #{node['mercury']['package']['bin']}"

  node.default['nagios']['nrpe_commands']['check_mercury_backend']['enabled'] = true
  node.default['nagios']['nrpe_commands']['check_mercury_backend']['interval'] = 300
  node.default['nagios']['nrpe_commands']['check_mercury_backend']['timeout'] = 30
  node.default['nagios']['nrpe_commands']['check_mercury_backend']['command'] = "#{ruby} #{sensu_path}/check-process.rb -p #{node['mercury']['package']['bin']} -W 1"

end
