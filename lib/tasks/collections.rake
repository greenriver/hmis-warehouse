###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

namespace :collections do
  desc 'Find and delete system collections with no live entities (never had any, or entities since deleted)'
  task :cleanup_orphaned_entities, [:dry_run] => :environment do |_task, args|
    dry_run = ['true', '1'].include?(args[:dry_run])

    puts '=' * 80
    puts 'Cleanup Orphaned System Collections'
    puts "Mode: #{dry_run ? 'DRY RUN' : 'LIVE'}"
    puts '=' * 80
    puts

    result = GrdaWarehouse::Tasks::CleanupOrphanedSystemCollections.new(dry_run: dry_run).run!

    if result[:candidates].empty?
      puts 'No orphaned system collections found.'
    else
      result[:candidates].each do |candidate|
        status = if dry_run
          'would delete'
        elsif result[:destroyed_ids].include?(candidate[:id])
          'deleted'
        else
          failure = result[:failed].find { |f| f[:id] == candidate[:id] }
          "ERROR: #{failure && failure[:error]}"
        end

        puts "Collection ##{candidate[:id]} \"#{candidate[:name]}\" (#{candidate[:collection_type]}) - " \
          "source: #{candidate[:source_type] || 'none'}##{candidate[:source_id]} " \
          "[entity rows: #{candidate[:entity_rows_count]}, access_controls: #{candidate[:access_controls_count]}] - #{status}"
      end
    end

    puts
    puts '=' * 80
    puts 'Summary:'
    puts "  Total candidates found: #{result[:candidates].size}"
    if dry_run
      puts "  Total that would be deleted: #{result[:candidates].size}"
      puts
      puts 'To actually delete these, run without dry_run:'
      puts '  rake collections:cleanup_orphaned_entities'
    else
      puts "  Total deleted: #{result[:destroyed_ids].size}"
      puts "  Total errors: #{result[:failed].size}"
    end
    puts '=' * 80
  end
end
