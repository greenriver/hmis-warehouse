#!/usr/bin/env ruby
require 'pathname'
require 'tempfile'
require 'fileutils'

app_root = Pathname.new File.expand_path('../../', __FILE__)

exit 0 if File.exist? File.join(app_root, '.git', 'MERGE_HEAD')

files = `git diff --name-only --staged`.split("\n")
todo_path = File.join(app_root, '.rubocop_todo.yml')

Tempfile.create do |tempfile|
  File.foreach(todo_path) do |line|
    trimmed = line
      .gsub(/^\s+- '(.+)'$/) { $1 }
      .chomp
    if files.include?(trimmed)
      puts line
    else
      tempfile << line
    end
  end

  tempfile.flush

  FileUtils.cp(tempfile.path, todo_path)
end

`git add .rubocop_todo.yml`
