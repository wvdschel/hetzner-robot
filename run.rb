#!/usr/bin/env ruby
dir = File.dirname(__FILE__)

origdir = Dir.pwd
Dir.chdir(dir)
load "hetzner-robot.rb"
load "csvgen.rb"
Dir.chdir(origdir)