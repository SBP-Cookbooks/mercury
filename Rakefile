#!/usr/bin/env rake

# Style tests. cookstyle (rubocop) and Foodcritic
namespace :style do
  begin
    require 'cookstyle'
    require 'rubocop/rake_task'

    desc 'Run Ruby style checks'
    RuboCop::RakeTask.new(:ruby)
  rescue LoadError => e
    puts ">>> Gem load error: #{e}, omitting style:ruby" unless ENV['CI']
  end

  begin
    require 'foodcritic'

    desc 'Run Chef style checks'
    FoodCritic::Rake::LintTask.new(:chef) do |t|
      t.options = {
        fail_tags: ['any'],
        progress: true,
      }
    end
  rescue LoadError
    puts ">>> Gem load error: #{e}, omitting style:chef" unless ENV['CI']
  end
end

desc 'Run all style checks'
task style: ['style:chef', 'style:ruby']

# ChefSpec
begin
  require 'rspec/core/rake_task'

  desc 'Run ChefSpec examples'
  RSpec::Core::RakeTask.new(:spec) do |t|
    t.pattern = Dir.glob('test/spec/unit/recipes/*_spec.rb')
    t.rspec_opts = '--format documentation'
  end
rescue LoadError => e
  puts ">>> Gem load error: #{e}, omitting spec" unless ENV['CI']
end

# Integration tests. Kitchen.ci
# namespace :integration do
#   begin
#     require 'kitchen/rake_tasks'
# 
#     desc 'Run kitchen integration tests'
#     Kitchen::RakeTasks.new
#   rescue StandardError => e
#     puts ">>> Kitchen error: #{e}, omitting #{task.name}" unless ENV['CI']
#   end
# end

# README generator
begin
  require 'knife_cookbook_doc/rake_task'

  desc 'Generate README'
  KnifeCookbookDoc::RakeTask.new(:doc) do |t|
    t.options[:cookbook_dir] = './'
    t.options[:constraints] = true
    t.options[:output_file] = 'README.md'
    t.options[:template_file] = "#{File.dirname(__FILE__)}/README.md.erb"
  end
rescue LoadError
  puts ">>> Gem load error: #{e}, omitting doc" unless ENV['CI']
end

# Default
task default: %w(style spec)
