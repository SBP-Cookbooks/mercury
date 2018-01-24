#
# Cookbook:: mercury
# Spec:: default
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
require 'spec_helper'

describe 'mercury::default' do
  context 'When all attributes are default, on a CentOS 7.3 system' do
    let(:chef_run) do
      # for a complete list of available platforms and versions see:
      # https://github.com/customink/fauxhai/blob/master/PLATFORMS.md
      runner = ChefSpec::ServerRunner.new(platform: 'centos', version: '7.3.1611')
      runner.converge(described_recipe)
    end

    it 'converges successfully' do
      expect { chef_run }.to_not raise_error
    end

    it 'installs the package' do
      expect(chef_run).to install_rpm_package('mercury')
    end

    it 'writes the config' do
      expect(chef_run).to create_file('/etc/mercury/mercury.toml')
    end

    it 'test the config' do
      expect(chef_run).to run_execute('config test')
    end

    it 'start the service' do
      expect(chef_run).to start_service('mercury')
    end
  end
end
