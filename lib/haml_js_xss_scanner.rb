#!/usr/bin/env ruby
# frozen_string_literal: true

require 'optparse'

class HamlJsXssScanner
  # Pattern to match JavaScript blocks in HAML
  JS_BLOCK_PATTERN = /^(\s*):javascript\b/

  # Pattern to match string interpolation in HAML
  INTERPOLATION_PATTERN = /\#{(?:[^{}]|\g<0>)*}/

  # Patterns that suggest proper escaping
  SAFE_PATTERNS = [
    /\.to_json(\W|.html_safe)/,
    /(^|\W)j[ (]/,
    /(^|\W)Oj\.dump[ (]/,
  ].freeze

  def initialize(options = {})
    @options = {
      paths: ['app/views', 'drivers/*/app/views'],
      extensions: ['.haml'],
      verbose: false,
      ci_mode: false,
    }.merge(options)

    @issues_found = 0
    @issues = []
  end

  def scan
    files_to_scan.each do |file|
      scan_file(file)
    end

    return if @issues.empty?

    puts "# Correct ruby interpolation in HAML inline Javascript\n\n"
    puts "## Instructions\n"
    puts '- Address the unescaped interpolated Ruby code in HAML Javascript templates'
    puts '- As you complete tasks and check files, update this file to track your progress.'
    puts '- ✅ DO: Use EITHER the ruby on rails `j(...)` helper OR `object.to_json` within interpolated ruby code. The goal is to reduce the risk of XSS'
    puts '- ✅ DO: Infer if the intention is to include an object literal OR a string and use the correct escaping'
    puts '- ✅ DO: You probably should use `to_json` when in doubt'
    puts "- ✅ DO: Use `j(...)` when it's clear the variable is a string"
    puts "- ✅ DO: Mark the item as blocked if it's ambiguous"
    puts '- ✅ DO: Ensure Javascript will still be valid'
    puts "- Note: You probably shouldn't be changing the javascript, just the interpolated ruby code"
    puts "- ❌ DON'T: Try to escape the literals using javascript"
    puts "- ❌ DON'T: use `j(...) when the variable could be something that isn't a string"
    puts "- ❌ DON'T: use BOTH `j(...)` helper OR `object.to_json`\n\n"
    puts '## Task list'

    @issues.each do |issue|
      puts "- [ ] `#{issue[:file]}`:#{issue[:line_number]} - #{issue[:interpolation]}"
    end

    puts "\nTotal issues found: #{@issues_found}"
    exit 1 if @options[:ci_mode] && @issues_found > 0
  end

  private

  def files_to_scan
    @options[:paths].sort.flat_map do |path|
      Dir.glob(File.join(path, '**', '*')).select do |file|
        @options[:extensions].any? { |ext| file.end_with?(ext) }
      end
    end
  end

  def scan_file(file)
    return unless File.file?(file)

    content = File.read(file)
    line_number = 0
    in_js_block = false

    content.each_line do |line|
      line_number += 1

      if line.match?(JS_BLOCK_PATTERN)
        in_js_block = true
        next
      end

      if in_js_block && !line.strip.empty?
        js_indentation = line.match(/^(\s*):javascript\b/)&.[](1)&.length || 0
        current_indentation = line.match(/^(\s*)/)&.[](1)&.length || 0

        in_js_block = false if js_indentation >= current_indentation && !line.strip.empty?
      end

      next unless in_js_block

      next unless line.match?(INTERPOLATION_PATTERN)

      interpolations = line.scan(INTERPOLATION_PATTERN)

      interpolations.each do |interpolation|
        next if safe_interpolation?(interpolation)

        @issues << {
          file: file,
          line_number: line_number,
          line: line.strip,
          interpolation: interpolation,
        }
        @issues_found += 1
      end
    end
  end

  def safe_interpolation?(interpolation)
    SAFE_PATTERNS.any? { |pattern| interpolation.match?(pattern) }
  end
end

# Parse command line options
options = {}
OptionParser.new do |opts|
  opts.banner = 'Usage: ruby haml_js_xss_scanner.rb [options]'

  opts.on('-p', '--paths PATH1,PATH2', Array, 'Comma-separated paths to scan (default: app/views,drivers/*/app/views)') do |paths|
    options[:paths] = paths
  end

  opts.on('-v', '--verbose', 'Enable verbose output') do
    options[:verbose] = true
  end

  opts.on('--ci', 'CI mode - exit with status 1 if issues found') do
    options[:ci_mode] = true
  end

  opts.on('-h', '--help', 'Show this help message') do
    puts opts
    exit
  end
end.parse!
