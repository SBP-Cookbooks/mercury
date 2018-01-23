guard :rspec, cmd: 'chef exec rspec', spec_paths: ['test/spec'], all_on_start: false do
  watch(%r{^test/spec/unit/*/(.+)_spec\.rb$})

  watch(%r{^recipes/(.+)\.rb$}) do |m|
    "test/spec/unit/recipes/#{m[1]}_spec.rb"
  end

  watch(%r{^resources/(.+)\.rb$}) do |m|
    "test/spec/unit/recipes/#{m[1]}_spec.rb"
  end
end
