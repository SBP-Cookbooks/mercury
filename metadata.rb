name             'mercury'
maintainer       'Schuberg Philis'
maintainer_email 'rdoorn@schubergphilis.com'
license          'Apache-2.0'
description      'Installs/Configures mercury'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          '1.2.8'
chef_version     '>= 12.5' if respond_to?(:chef_version)

issues_url 'https://github.com/sbp-cookbooks/mercury/issues'
source_url 'https://github.com/sbp-cookbooks/mercury'

# Supported OSes:
%w(centos redhat).each do |os|
  supports os
end

# Dependencies:
depends 'ssl_certificate', '~> 2.1.0' # ~CG001
depends 'logrotate', '~> 2.1' # ~CG001

gem 'toml-rb', '= 1.0.0'
