#!/usr/bin/env ruby
def run_command(command) 
  if command == 'fetch'
    puts "Fetching new data"
    load "hetzner-robot.rb"
  elsif command == 'csv'
    puts "Generating new CSV data"
    load "csvgen.rb"
  else
    puts "Unknown command: #{command}"
  end
end

dir = File.dirname(__FILE__)

commands = ARGV.map { |a| a.downcase }

origdir = Dir.pwd
Dir.chdir(dir)
commands.each { |c| run_command(c) }
File.open('hetzner-robot.log', 'a') { |f| f.puts "Ran at #{Time.now}" }
Dir.chdir(origdir)
