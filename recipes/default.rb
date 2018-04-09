#
# Cookbook:: mercury
# Recipe:: application
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

# toml is required to build the config file
require 'toml-rb'

config = Mash.new

# setup all default variables
config['cluster'] = node['mercury']['cluster'].to_hash

mercury_version = Gem::Version.new(node['mercury']['package']['version'].split('_')[0].split('-')[0])
if mercury_version < Gem::Version.new('0.9.3')
  config['cluster']['binding'] = node['fqdn']
  config['cluster']['settings']['tls'] = config['cluster']['tls']

  # parse searches of all cluster nodes, so we know who is part of our cluster
  config['cluster']['parsed_nodes'] ||= []
  config['cluster']['nodes'].clone.each do |data|
    if data['search']
      result = if Chef::Config[:solo]
                 Chef::Log.warn('Search is not supported in SOLO')
                 []
               else
                 search(:node, data[:search],
                        filter_result: {
                          'hostname' => ['fqdn'],
                          'ip' => ['ipaddress'],
                        })
               end
      result.each do |k|
        config['cluster']['parsed_nodes'] << k['hostname']
      end
    elsif data['host']
      config['cluster']['parsed_nodes'] << data['host']
    else
      Chef::Log.warn("Invalid cluster node definition (want search or host, got #{data})")
    end
  end

  # if the first entry is nil, we failed to resolve our selves - happens first chef run
  config['cluster']['parsed_nodes'] = [node['fqdn']] if config['cluster']['parsed_nodes'][0].nil?

  config['cluster']['nodes'] = config['cluster']['parsed_nodes']
  config['cluster'].delete('parsed_nodes')

elsif mercury_version >= Gem::Version.new('0.9.3')

  authkey = node['mercury']['cluster']['name']
  port = node['mercury']['cluster']['settings']['port']
  foundclusternodes = []
  clusternodes = []

  config['cluster']['nodes'].clone.each do |data|
    if data['search']
      result = search(:node, data[:search],
                      filter_result: {
                        'hostname' => ['fqdn'],
                        'ip' => ['ipaddress'],
                      })
      result.each do |n|
        foundclusternodes << { name: n['hostname'], addr: "#{n['ip']}:#{port}", authkey: authkey }
      end
    elsif data['host']
      config['cluster']['parsed_nodes'] << { name: data['hostname'], addr: "#{data['ip']}:#{port}", authkey: authkey }
    else
      Chef::Log.warn("Invalid cluster node definition (want search or host, got #{data})")
    end
  end

  # remove self from cluster node list and add self to binding instead
  foundclusternodes.each do |cn|
    if cn[:name] == node[:fqdn] || node[:fqdn].empty? # ~FC001 ~FC019
      config['cluster']['binding'] = cn
    else
      clusternodes << cn
    end
  end
  config['cluster']['nodes'] = clusternodes

else
  raise 'Unknown mercury version number'
end

# Clone all variables so we can parse and edit them
config['loadbalancer'] = node['mercury']['loadbalancer'].to_hash.clone
config['web'] = node['mercury']['web'].to_hash.clone
config['dns'] = node['mercury']['dns'].to_hash.clone

# Cluster SSL connection
cert = ssl_certificate 'cluster_communication' do
  namespace node['openssl']['ssl_certificate']
  cert_name 'cluster.mercury.crt'
  key_name 'cluster.mercury.key'
  subject_alternate_names [node['hostname']]
  notifies :run, 'execute[config test and reload]'
end
file "#{cert.cert_dir}/cluster.mercury.key" do
  content cert.key_content
end
config['cluster']['tls']['certificatefile'] = "#{cert.cert_dir}/cluster.mercury.crt"
config['cluster']['tls']['certificatekey'] = "#{cert.cert_dir}/cluster.mercury.key"

# Web SSL connection
cert = ssl_certificate 'web_communication' do
  namespace node['openssl']['ssl_certificate']
  cert_name 'web.mercury.crt'
  key_name 'web.mercury.key'
  subject_alternate_names [node['hostname']]
  notifies :run, 'execute[config test and reload]'
end
file "#{cert.cert_dir}/web.mercury.key" do
  content cert.key_content
  not_if { ::File.exist?("#{cert.cert_dir}/web.mercury.key") }
end
config['web']['tls']['certificatefile'] = "#{cert.cert_dir}/web.mercury.crt"
config['web']['tls']['certificatekey'] = "#{cert.cert_dir}/web.mercury.key"

config['logging'] ||= {}
config['logging']['level'] = node['mercury']['logging']['level']
config['logging']['output'] = node['mercury']['logging']['output']

config['loadbalancer']['pools'].each do |poolname, pool|
  # parse all listeners and see if we need to setup SSL certificates
  if pool['listener'].is_a?(Hash) && pool['listener']['mode'] == 'https'
    # No databag item, asume files are on disk
    cert = ssl_certificate poolname do
      namespace node['openssl']['ssl_certificate']

      # certificate name is that of the vip, and self signed by default, but add all alternative names of the backend hostname.domains
      # subject_alternate_names pool[:backends].map { |_, b| "#{b['dnsentry']['hostname']}.#{b['dnsentry']['domain']}" }
      subject_alternate_names pool[:backends].map { |_, b| "#{b['dnsentry']['hostname']}.#{b['dnsentry']['domain']}" if b['dnsentry'] }.grep(String)
      cert_name "#{poolname}.mercury.crt"
      key_name "#{poolname}.mercury.key"
      if pool['listener']['tls'].nil?
        raise "No TLS config specified for listener in HTTPS mode (pool: #{poolname})"
      end

      if !pool['listener']['tls']['databagitem'].nil? && !pool['listener']['tls']['databagitem'].empty?
        source 'data-bag'
        encrypted true
        bag pool['listener']['tls']['databagname'] ? pool['listener']['tls']['databagname'] : 'mercury'
        key_item pool['listener']['tls']['databagitem']
        cert_item pool['listener']['tls']['databagitem']
        cert_item_key pool['listener']['tls']['certificatefile']
        key_item_key pool['listener']['tls']['certificatekey']
      end
      notifies :run, 'execute[config test and reload]'
    end
    # the ssl_certificate provider does not write the key..
    file "#{cert.cert_dir}/#{poolname}.mercury.key" do
      content cert.key_content
    end
    pool['listener']['tls']['certificatefile'] = "#{cert.cert_dir}/#{poolname}.mercury.crt"
    pool['listener']['tls']['certificatekey'] = "#{cert.cert_dir}/#{poolname}.mercury.key"

  end
  # parse searches of all backend nodes
  next unless pool['backends']
  pool['backends'].each do |backendname, backend|
    nodelist = []
    next unless backend['nodes']

    # mercury >= 0.10 supports multiple healthchecks
    if !backend['healthcheck'].nil? && mercury_version >= Gem::Version.new('0.10.0')
      backend['healthchecks'] = [backend['healthcheck']]
    end

    # Backend certificate handler, only create certificates if they are in a databag.
    # if they need to be generated, it would have been done on the main vip
    # if they need to be files without databag, write them your self.
    if backend['tls'] && !backend['tls']['databagitem'].nil? && !backend['tls']['databagitem'].empty?
      cert = ssl_certificate "#{poolname}.#{backendname}" do
        namespace node['openssl']['ssl_certificate']
        cert_name "#{poolname}.#{backendname}.mercury.crt"
        key_name "#{poolname}.#{backendname}.mercury.key"
        source 'data-bag'
        encrypted true
        bag backend['tls']['databagname'] ? backend['tls']['databagname'] : 'mercury'
        key_item backend['tls']['databagitem']
        cert_item backend['tls']['databagitem']
        cert_item_key backend['tls']['certificatefile']
        key_item_key backend['tls']['certificatekey']
        notifies :run, 'execute[config test and reload]'
      end
      # the ssl_certificate provider does not write the key..
      file "#{cert.cert_dir}/#{poolname}.#{backendname}.mercury.key" do
        content cert.key_content
      end
      backend['tls']['certificatefile'] = "#{cert.cert_dir}/#{poolname}.#{backendname}.mercury.crt"
      backend['tls']['certificatekey'] = "#{cert.cert_dir}/#{poolname}.#{backendname}.mercury.key"
    end

    backend['nodes'].each do |n|
      if n['search']
        Chef::Log.warn("Searching nodes for backend #{backendname}, query: #{n['search']}")
        backend_nodes = search(:node, n['search'],
                               filter_result: {
                                 'hostname' => ['name'],
                                 'ip' => ['ipaddress'],
                               })
      else
        backend_nodes = [{ 'hostname' => n['hostname'], 'ip' => n['ip'] }]
      end
      # chef can return multiple in search, so go through all of them
      backend_nodes.each do |m|
        nodelist << { hostname: m['hostname'] ? m['hostname'] : m['ip'], ip: m['ip'] ? m['ip'] : m['hostname'], port: n['port'] }
      end
    end
    if nodelist.empty?
      Chef::Log.warn("We have 0 nodes for backend #{backendname}!")
    end
    backend['nodes'] = nodelist
  end
end

package_name = node['mercury']['package']['name']
package_version = node['mercury']['package']['version']
package_arch = node['mercury']['package']['arch']
package_source = node['mercury']['package']['source']

# Install the RPM
remote_file "#{Chef::Config[:file_cache_path]}/#{package_name}-#{package_version}-1.#{package_arch}.rpm" do
  source package_source.to_s
  action :create
end

rpm_package 'mercury' do
  source "#{Chef::Config[:file_cache_path]}/#{package_name}-#{package_version}-1.#{package_arch}.rpm"
  action :install
  notifies :run, 'execute[config test and restart]'
end

# Write the config file
file node['mercury']['package']['config'] do
  content TomlRB.dump(config)
  mode 0o0644
  notifies :run, 'execute[config test and reload]'
end

# Always do the config test, chef needs to fail if this fails, we need to fix the LB urgently
execute 'config test' do
  command "#{node['mercury']['package']['bin']} --config-file #{node['mercury']['package']['config']} -check-config"
end

# Ensure mercury is started
service 'mercury' do
  action %i(enable start)
end

execute 'systemctl daemon-reload' do
  action :nothing
end

execute 'config test and restart' do
  command "#{node['mercury']['package']['bin']} --config-file #{node['mercury']['package']['config']} -check-config"
  notifies :restart, 'service[mercury]'
  notifies :run, 'execute[systemctl daemon-reload]'
  action :nothing
end

execute 'config test and reload' do
  command "#{node['mercury']['package']['bin']} --config-file #{node['mercury']['package']['config']} -check-config"
  action :nothing
  notifies :reload, 'service[mercury]'
end

# Only if we log to a path do we do logrotate
if node['mercury']['logging']['output'] =~ %r{/}
  logrotate_app 'mercury-gslb' do
    path       node['mercury']['logging']['output']
    options    node['mercury']['logging']['rotate']['options']
    frequency  node['mercury']['logging']['rotate']['frequency']
    rotate     node['mercury']['logging']['rotate']['rotate']
    postrotate node['mercury']['logging']['rotate']['postrotate']
    create     node['mercury']['logging']['rotate']['create']
  end
end

# For syslog logging disable rate-limiting the log
if node['mercury']['logging']['output'] == 'syslog'
  cookbook_file '/etc/systemd/journald.conf' do
    source 'journald.conf'
    notifies :restart, 'service[systemd-journald]'
  end

  service 'systemd-journald' do
    action :nothing
  end
end
