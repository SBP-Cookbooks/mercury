# Inspec test for recipe mercury::default

# The Inspec reference, with examples and extensive documentation, can be
# found at http://inspec.io/docs/reference/resources/

unless os.windows?
  describe user('root'), :skip do
    it { should exist }
  end
end

describe port(9001), :skip do
  it { should be_listening }
end

describe port(9000), :skip do
  it { should be_listening }
end
