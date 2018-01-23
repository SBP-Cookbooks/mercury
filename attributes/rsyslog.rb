#
# Cookbook:: mercury
# Attributes:: rsyslog
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

# Remove default log rule for rsyslog, and make Mercury log to local5
node.default['rsyslog']['default_facility_logs'].delete('*.info;mail.none;authpriv.none;cron.none')
default['rsyslog']['default_facility_logs']['*.info;mail.none;authpriv.none;cron.none;local5.none'] = "#{node['rsyslog']['default_log_dir']}/messages"
default['rsyslog']['default_facility_logs']['local5.*'] = "#{node['rsyslog']['default_log_dir']}/mercury"

# Disable rate limiting so we log all messages
default['rsyslog']['additional_directives']['imjournalRatelimitInterval'] = 0
default['rsyslog']['additional_directives']['SystemLogRateLimitInterval'] = 0
default['rsyslog']['additional_directives']['SystemLogRateLimitBurst'] = 0
