#!/usr/bin/env ruby

require 'fileutils'

target = '.env.local'

env_files =
  Dir.glob(".env.*").reject do |env_file|
    env_file == '.env' ||
    env_file == '.env.local' ||
    env_file == '.env.test' ||
    env_file == '.env.development'
  end

bad = true
while (bad)
  puts "Select an environment:"
  env_files.each.with_index do |env_file, index|
    puts "#{"%2d" % index}: #{env_file}"
  end
  @response = gets.chomp.to_i

  if @response < env_files.length && @response >= 0
    bad=false
  end
end

env_file = env_files[@response]


if File.exists?(target) && !File.symlink?(target)
  puts "Refusing to link to #{target} because it's a regular file."
else
  puts "Linking .env.local to #{env_file}"

  FileUtils.rm_f(target)
  FileUtils.ln_s(env_file, target)


  if !ENV['TMUX'].nil?
    system("tmux send-keys 'source .env.local'")
  else
    puts "Type this:\nsource .env.local"
  end
end
