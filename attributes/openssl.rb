#
# Cookbook:: mercury
# Attributes:: openssl
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

# Generate a self-signed certificate by default
default['openssl'].tap do |_openssl|
  node.default['ssl_certificate']['ssl_cert']['source'] = 'self-signed'
  node.default['ssl_certificate']['ssl_key']['source'] = 'self-signed'
end
