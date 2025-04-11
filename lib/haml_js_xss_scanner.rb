# !/usr/bin/env ruby
# frozen_string_literal: true

# Scans HAML templates for potential XSS vulnerabilities in inline JavaScript blocks.
# Specifically looks for unsafe Ruby interpolations (#{...}) within :javascript blocks
# that aren't properly escaped using j(...) or to_json. Generates a report of
# findings and can be used in CI pipelines to prevent unsafe code from being merged.

require 'optparse'

class HamlJsXssScanner
  JS_BLOCK_PATTERN = /^(\s*):javascript\b/
  INTERPOLATION_PATTERN = /\#{(?:[^{}]|\g<0>)*}/

  SAFE_PATTERNS = [
    /\.html_safe\s*/,
    /\.to_json\s*/,
    /(^|\W)j[ (]/,
    /(^|\W)raw[ (]/,
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
      puts "Scanning #{file}" if @options[:verbose]
      scan_file(file)
    end

    return if @issues.empty?

    puts <<~INSTRUCTIONS
      # Correct ruby interpolation in HAML inline Javascript

      ## Task list
    INSTRUCTIONS

    @issues.group_by { |issue| issue[:file] }.each do |file, issues|
      puts "- [ ] `#{file}` - #{issues.size} interpolation(s) to fix on lines #{issues.map { |issue| issue[:line_number] }.uniq.join(', ')}"
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
    js_block_indent = nil

    content.each_line do |line|
      line_number += 1

      if line.match?(JS_BLOCK_PATTERN)
        js_block_indent = line[/^(\s*)/, 1].length
        in_js_block = true
        next
      end

      if in_js_block
        current_indent = line[/^(\s*)/, 1].length
        in_js_block = false if line.strip != '' && current_indent <= js_block_indent
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
