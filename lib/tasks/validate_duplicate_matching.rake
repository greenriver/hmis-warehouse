# frozen_string_literal: true

# TODO: remove after QA of #8391
namespace :validate do
  desc 'Compare legacy vs new duplicate matching implementations'
  task duplicate_matching: :environment do
    puts 'Validating duplicate matching implementations...'
    puts '=' * 80

    methods = [
      :exact_ssn_matches,
      :exact_name_matches,
      :exact_dob_matches,
      :exact_ssn_matches_for_unprocessed,
      :exact_name_matches_for_unprocessed,
      :exact_dob_matches_for_unprocessed,
    ]

    task = GrdaWarehouse::Tasks::IdentifyDuplicates.new(run_post_processing: false)
    all_match = true

    methods.each do |method_name|
      puts "\nValidating legacy #{method_name}..."
      legacy_results = task.send(method_name, legacy: true).to_set

      puts "Validating refactored #{method_name}..."
      new_results = task.send(method_name, legacy: false).to_set

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
