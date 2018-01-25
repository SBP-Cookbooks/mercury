# Inspec test for recipe mercury::default

# The Inspec reference, with examples and extensive documentation, can be
# found at http://inspec.io/docs/reference/resources/

unless os.windows?
  describe user('root'), :skip do
    it { should exist }
  end
end

describe port(9000), :skip do
  it { should be_listening }
end

describe bash('curl -sS localhost:9001/') do
  its('stdout') { should_not match %r/HTTP Status 404/i }
  its('stderr') { should eq '' }
end

describe file('/etc/mercury/mercury.toml') do
  its('content') { should match %r/web.mercury.crt/ }
end

describe file('/etc/mercury/mercury.toml') do
  its('content') { should match %r/TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384", "TLS_ECDHE_RSA_WITH_AES_256_CBC_SHA", "TLS_RSA_WITH_AES_256_GCM_SHA384", "TLS_RSA_WITH_AES_256_CBC_SHA/ }
end
