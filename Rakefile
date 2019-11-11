# -*- coding: utf-8 -*-
$:.unshift("/Library/RubyMotion/lib")
$:.unshift("~/.rubymotion/rubymotion-templates")

platform = ENV.fetch('platform', 'ios')
require "motion/project/template/#{platform}"
require 'bundler/setup'
require 'motion/project/template/gem/gem_tasks'

if ARGV.join(' ') =~ /spec/
  Bundler.require :default, :spec
else
  Bundler.require
end

require 'cdq'
require 'motion-stump'
require 'ruby-xcdm'
require 'motion-yaml'

Motion::Project::App.setup do |app|
  # Use `rake config' to see complete project settings.
  app.name = 'CDQ'
  app.vendor_project('vendor/cdq/ext', :static)
end

task :"build:simulator" => :"schema:build"
