###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# TODO: remove after QA of #8391
namespace :validate do
  desc 'Compare legacy vs new duplicate matching implementations and time each. Limit with METHODS=a,b (default: all six)'
  task duplicate_matching: :environment do
    puts 'Validating duplicate matching implementations...'
    puts '=' * 80

    all_methods = [
      :exact_ssn_matches,
      :exact_name_matches,
      :exact_dob_matches,
      :exact_ssn_matches_for_unprocessed,
      :exact_name_matches_for_unprocessed,
      :exact_dob_matches_for_unprocessed,
    ]

    # METHODS=exact_ssn_matches,exact_dob_matches limits the run, e.g. to skip legacy queries that time out
    requested_methods = ENV.fetch('METHODS', '').
      split(',').
      map(&:strip).
      reject(&:blank?).
      map(&:to_sym)
    unknown_methods = requested_methods - all_methods
    abort "Unknown METHODS: #{unknown_methods.join(', ')}. Valid: #{all_methods.join(', ')}" if unknown_methods.any?

    methods = requested_methods.presence || all_methods

    task = GrdaWarehouse::Tasks::IdentifyDuplicates.new(run_post_processing: false)
    all_match = true

    methods.each do |method_name|
      puts "\nValidating legacy #{method_name}..."
      legacy_started_at = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      legacy_results = task.send(method_name, legacy: true).to_set
      legacy_elapsed = Process.clock_gettime(Process::CLOCK_MONOTONIC) - legacy_started_at
      puts "  legacy elapsed: #{legacy_elapsed.round(2)}s"

      puts "Validating refactored #{method_name}..."
      new_started_at = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      new_results = task.send(method_name, legacy: false).to_set
      new_elapsed = Process.clock_gettime(Process::CLOCK_MONOTONIC) - new_started_at
      puts "  refactored elapsed: #{new_elapsed.round(2)}s"

      if method_name.end_with?('_for_unprocessed')
        # Both paths look up unprocessed_ids twice (the blank? guard and the query),
        # so each elapsed time above includes two lookups on top of the SQL.
        lookup_started_at = Process.clock_gettime(Process::CLOCK_MONOTONIC)
        task.send(:unprocessed_ids)
        lookup_elapsed = Process.clock_gettime(Process::CLOCK_MONOTONIC) - lookup_started_at
        puts "  unprocessed_ids lookup: #{lookup_elapsed.round(2)}s (each path above includes 2 lookups)"
      end

      if legacy_results == new_results
        puts "  ✓ MATCH (#{new_results.count} pairs)"
        next
      end

      all_match = false
      puts '  ✗ MISMATCH!'
      puts "    Legacy count: #{legacy_results.count}"
      puts "    New count:    #{new_results.count}"

      missing = legacy_results - new_results
      extra = new_results - legacy_results

      puts "    Missing from new: #{missing.count}"
      puts "    Extra in new:     #{extra.count}"

      unless missing.empty?
        puts "\n    First 50 pairs missing from new implementation:"
        missing.take(50).each { |pair| puts "      #{pair.inspect}" }
      end

      next if extra.empty?

      puts "\n    First 50 extra pairs in new implementation:"
      extra.take(50).each { |pair| puts "      #{pair.inspect}" }
    end

    puts "\n" + '=' * 80
    if all_match
      puts '✓ All methods match! Safe to proceed with rollout.'
    else
      puts '✗ Mismatches detected. Review differences before rollout.'
      exit 1
    end
  end
end
