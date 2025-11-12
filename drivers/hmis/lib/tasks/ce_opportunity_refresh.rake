# frozen_string_literal: true

# Helper task to close stale CE opportunities and remint fresh ones
# usage:
# - rails driver:hmis:refresh_stale_opportunities
# - passing optional candidate_pool_ids: rails driver:hmis:refresh_stale_opportunities[1,2,3]
desc 'Close stale CE opportunities and create fresh ones with updated rules'
task :refresh_stale_opportunities, [:pool_ids] => [:environment] do |_t, args|
  raise 'CE is not enabled' unless Hmis::Ce.configuration.enabled?

  pool_ids = args[:pool_ids]&.split(',')&.map(&:to_i)

  refresher = Hmis::Ce::OpportunityRefresher.new

  puts '=' * 80
  puts 'Refreshing Stale CE Opportunities'
  puts '=' * 80
  if pool_ids.present?
    puts "Filtering to candidate pool IDs: #{pool_ids.join(', ')}"
  else
    puts 'Refreshing ALL stale opportunities'
  end
  puts ''

  result = refresher.refresh_stale_opportunities(candidate_pool_ids: pool_ids)

  puts "✓ Closed #{result[:closed_count]} stale opportunities"
  if result[:closed_opportunity_unit_ids].any?
    puts "  Units: #{result[:closed_opportunity_unit_ids].sort.join(', ')}"
  end

  puts ''
  puts "✓ Created #{result[:created_count]} fresh opportunities"
  if result[:created_opportunity_ids].any?
    puts "  New opportunity IDs: #{result[:created_opportunity_ids].sort.join(', ')}"
  end

  if result[:closed_count].zero? && result[:skipped_opportunity_ids].empty?
    puts ''
    puts 'No stale opportunities found to refresh.'
  end

  puts ''
  puts '=' * 80
  puts 'DONE'
  puts '=' * 80
end
