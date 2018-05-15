#
# Cookbook:: mercury
# Attributes:: mercury
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
# default['sbp_test']['setting'] = false

default['mercury'].tap do |mercury|
  # Package information
  mercury['package']['name'] = 'mercury'
  mercury['package']['version'] = '0.12.5'
  mercury['package']['arch'] = 'x86_64'
  mercury['package']['source'] = "https://github.com/schubergphilis/mercury/releases/download/#{mercury['package']['version']}/mercury-#{mercury['package']['version']}-1.#{mercury['package']['arch']}.rpm"
  mercury['package']['config'] = '/etc/mercury/mercury.toml'
  mercury['package']['bin'] = '/usr/sbin/mercury'
  mercury['package']['pid'] = '/run/mercury.pid'

  # GLB logging INFO for prod, other environments debug
  mercury['logging']['level'] = 'info'
  mercury['logging']['output'] = 'syslog'

  # Logrotate for  when logging to a file
  mercury['logging']['rotate']['postrotate'] = "kill -1 `cat #{node['mercury']['package']['pid']}`"
  mercury['logging']['rotate']['frequency'] = 'daily'
  mercury['logging']['rotate']['rotate'] = 30
  mercury['logging']['rotate']['options'] = ['compress']
  mercury['logging']['rotate']['create'] = '644 root root'

  # GLB cluster communication vip
  mercury['cluster']['name'] = "GLB_#{node.chef_environment.upcase}"
  mercury['cluster']['settings']['connection_timeout'] = 10
  mercury['cluster']['settings']['connection_retry_interval'] = 10
  mercury['cluster']['settings']['ping_interval'] = 5
  mercury['cluster']['settings']['ping_timeout'] = 11
  mercury['cluster']['settings']['port'] = 9000

  mercury['cluster']['tls']['insecureskipverify'] = true
  mercury['cluster']['tls']['minversion'] = 'VersionTLS12'
  mercury['cluster']['tls']['ciphersuites'] = %w(TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384 TLS_ECDHE_RSA_WITH_AES_256_CBC_SHA TLS_RSA_WITH_AES_256_GCM_SHA384 TLS_RSA_WITH_AES_256_CBC_SHA)
  mercury['cluster']['tls']['curvepreferences'] = %w(CurveP521 CurveP384 CurveP256)

  mercury['cluster']['nodes'] = {}

  # DNS Server
  mercury['dns']['binding'] = node['fqdn']
  mercury['dns']['port'] = 53
  mercury['dns']['domains'] = {}

  # WEB Server
  mercury['web']['binding'] = '0.0.0.0' # bind on all adresses
  mercury['web']['port'] = 9001
  mercury['web']['tls']['minversion'] = 'VersionTLS12'
  mercury['web']['tls']['ciphersuites'] = %w(TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384 TLS_ECDHE_RSA_WITH_AES_256_CBC_SHA TLS_RSA_WITH_AES_256_GCM_SHA384 TLS_RSA_WITH_AES_256_CBC_SHA)
  mercury['web']['tls']['curvepreferences'] = %w(CurveP521 CurveP384 CurveP256)

  # Networks
  # none are set by default

  # Settings
  mercury['loadbalancer']['settings']['default_balance_method'] = 'roundrobin'
  mercury['loadbalancer']['pools'] = {}
end
