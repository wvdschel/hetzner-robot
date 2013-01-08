#!/usr/bin/env ruby
dir = File.dirname(__FILE__)

origdir = Dir.pwd
Dir.chdir(dir)
load "hetzner-robot.rb"
load "csvgen.rb"
File.open('hetzner-robot.log', 'a') { |f| f.puts "Ran at #{Time.now}" }
Dir.chdir(origdir)
