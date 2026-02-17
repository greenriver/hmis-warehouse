#!/usr/bin/env ruby
# frozen_string_literal: true

require 'json'

# This script determines the test matrix for CI based on the event type,
# commit message, and manual inputs. It outputs GitHub Actions compatible
# variables to GITHUB_OUTPUT.

class CiMatrixRouter
  def initialize
    @event_name = ENV['EVENT_NAME']
    @input_test_path = ENV['INPUT_TEST_PATH']
    @input_with_okta = ENV['INPUT_WITH_OKTA'] == 'true'
    @input_testkit_check_all_table_results = ENV['INPUT_TESTKIT_CHECK_ALL_TABLE_RESULTS'] == 'true'
    @input_with_logging = ENV['INPUT_WITH_LOGGING'] == 'true'
    @input_with_profiling = ENV['INPUT_WITH_PROFILING'] == 'true'
    @buckets_file = ENV['BUCKETS_FILE'] || '.github/rspec_buckets.json'
    @commit_msg = fetch_commit_message
  end

  def run
    focus_path = determine_focus_path
    routing = determine_routing(focus_path)
    unit_groups = build_unit_groups(focus_path, routing[:run_unit])

    outputs = {
      unit_matrix: { test_group: unit_groups }.to_json,
      run_unit: !unit_groups.empty?,
      run_hmis: routing[:run_hmis],
      run_warehouse: routing[:run_warehouse],
      focused_path: focus_path,
      okta: @input_with_okta || @commit_msg.include?('with-okta'),
      testkit_check_all_table_results: @input_testkit_check_all_table_results || @commit_msg.include?('testkit-check-all-results'),
      logging: @input_with_logging || @commit_msg.include?('with-logging'),
      profiling: @input_with_profiling || @commit_msg.include?('ci-profile'),
    }

    log_routing_decisions(focus_path, routing, outputs)
    write_outputs(outputs)
  end

  private

  def fetch_commit_message
    return ENV['COMMIT_MSG'] unless ENV['COMMIT_MSG'].nil?

    # Ensure we are not in a shallow clone which breaks history-based routing
    is_shallow = `git rev-parse --is-shallow-repository 2>/dev/null`.strip == 'true'
    warn 'WARNING: Shallow clone detected. Routing may be inaccurate.' if is_shallow

    # Try to get the message from HEAD, and if it looks like a merge commit (common in CI),
    # also check the second parent (the branch being merged).
    msg = `git log -1 --pretty=%B 2>/dev/null`.strip
    if @event_name == 'pull_request'
      # In GitHub Actions PR events, HEAD is a merge commit where HEAD^2 is the PR branch.
      # Check if HEAD^2 exists before trying to read it (e.g., in shallow clones or
      # non-merge commits, this ref won't exist).
      if system('git rev-parse --verify HEAD^2 >/dev/null 2>&1')
        head2_msg = `git log -1 --pretty=%B HEAD^2 2>/dev/null`.strip
        msg += "\n#{head2_msg}" unless head2_msg.empty?
      end
    end
    msg
  end

  def log_routing_decisions(focus_path, routing, outputs)
    puts 'CI Routing Decisions:'
    puts "  Event: #{@event_name}"
    puts "  Full Commit Message:\n---\n#{@commit_msg}\n---"
    puts "  Focus Path: #{focus_path || 'none'}"
    puts "  Routing: #{routing}"
    puts "  Outputs: #{outputs.reject { |k| k == :unit_matrix }}"
  end

  def determine_focus_path
    # Parse focus path from workflow input or commit message
    # Expected format: "ci-focus: path/to/spec" anywhere in commit message
    path = @input_test_path&.strip
    return validate_path(path) if path && !path.empty?

    path = @commit_msg[/ci-focus:\s*([^\]\n]+)/, 1]&.strip
    path && !path.empty? ? validate_path(path) : nil
  end

  def validate_path(path)
    return nil if path.nil? || path.empty?

    # Whitelist: Only allow alphanumerics, slashes, dots, underscores, hyphens, spaces and glob stars
    # This prevents shell injection by rejecting metacharacters like ; | & ` $ ( ) etc.
    if path =~ /\A[a-zA-Z0-9\/._\-* ]+\z/
      path
    else
      warn "ERROR: Unsafe characters detected in test path: #{path}"
      warn 'Test paths must only contain: a-z A-Z 0-9 / _ - . * and spaces'
      nil
    end
  end

  def determine_routing(focus_path)
    is_hmis = focus_path&.include?('drivers/hmis/spec/system')
    is_warehouse = focus_path&.include?('spec/system/rails')
    has_focus = !focus_path.nil?

    {
      run_unit: !has_focus || (!is_hmis && !is_warehouse),
      run_hmis: is_hmis || (!has_focus && @event_name == 'pull_request'),
      run_warehouse: is_warehouse || (!has_focus && @event_name == 'pull_request'),
    }
  end

  def build_unit_groups(focus_path, run_unit)
    return [] unless run_unit
    return [{ id: 'focused', test_path: focus_path }] if focus_path

    groups = []
    if File.exist?(@buckets_file)
      JSON.parse(File.read(@buckets_file)).each do |bucket|
        groups << {
          id: "ci_#{bucket['id'].tr('-', '_')}",
          tag: "ci_bucket:#{bucket['id']}",
        }
      end
    end
    groups << { id: 'ci_default', tag: '~ci_bucket', okta: true, logging: true }
    groups
  end

  def write_outputs(outputs)
    File.open(ENV['GITHUB_OUTPUT'], 'a') do |f|
      outputs.each do |key, value|
        f.puts "#{key}=#{value}"
      end
    end
  end
end

CiMatrixRouter.new.run if __FILE__ == $PROGRAM_NAME
