# frozen_string_literal: true

###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

namespace :paper_trail do
  desc 'De-duplicate paper trail version records for models affected by double has_paper_trail bug'
  task :deduplicate_versions, [:dry_run] => :environment do |_task, args|
    # A dry run is the default. To do a live run, pass `false`.
    # Example: railse "paper_trail:deduplicate_versions[false]"
    dry_run = args[:dry_run] != 'false'

    puts '=' * 80
    puts 'Paper Trail Version De-duplication Script'
    puts "Mode: #{dry_run ? 'DRY RUN' : 'LIVE'}"
    puts '=' * 80
    puts

    # Models that were affected by the double paper trail bug
    affected_models = [
      'HmisExternalApis::AcHmis::ReferralPosting',
      'HmisExternalApis::AcHmis::ReferralRequest',
      'HmisExternalApis::AcHmis::Referral',
      'HmisExternalApis::AcHmis::ReferralHouseholdMember',
    ]

    total_duplicates_found = 0
    total_duplicates_removed = 0

    affected_models.each do |model_name|
      puts "Processing #{model_name}..."

      # Find groups of versions with identical attributes (including created_at timestamp).
      # True duplicates from the double has_paper_trail bug will have the exact same created_at.
      duplicate_groups = GrdaWarehouse::Version.where(item_type: model_name).
        group(:item_id, :event, :whodunnit, :object_changes, :created_at).
        having('COUNT(*) > 1').
        pluck(:item_id, :event, :whodunnit, :object_changes, :created_at)

      if duplicate_groups.empty?
        puts '  No duplicates found'
        puts
        next
      end

      puts "  Found #{duplicate_groups.size} groups of duplicates"

      duplicate_groups.each do |item_id, event, whodunnit, object_changes, created_at|
        group = GrdaWarehouse::Version.where(
          item_type: model_name,
          item_id: item_id,
          event: event,
          whodunnit: whodunnit,
          object_changes: object_changes,
          created_at: created_at,
        ).order(:id).to_a

        total_duplicates_found += group.size - 1

        # Keep the version with metadata (enrollment_id, client_id, or project_id) if available,
        # otherwise keep the first one (lowest ID)
        version_to_keep = group.min_by do |v|
          has_metadata = [v.enrollment_id, v.client_id, v.project_id].any?(&:present?)
          [has_metadata ? 0 : 1, v.id]
        end

        versions_to_delete = group - [version_to_keep]

        puts "    Item #{item_id}, #{event}: keeping version #{version_to_keep.id}, removing #{versions_to_delete.size} duplicate(s)"

        if dry_run
          puts "      Would delete versions: #{versions_to_delete.map(&:id).join(', ')}"
        else
          deleted_count = GrdaWarehouse::Version.where(id: versions_to_delete.map(&:id)).delete_all
          total_duplicates_removed += deleted_count
          puts "      Deleted #{deleted_count} version(s)"
        end
      end

      puts
    end

    puts '=' * 80
    puts 'Summary:'
    puts "  Total duplicate versions found: #{total_duplicates_found}"
    if dry_run
      puts "  Total duplicate versions that would be removed: #{total_duplicates_found}"
      puts
      puts 'To actually remove duplicates, run with `false` as an argument:'
      puts '  rake "paper_trail:deduplicate_versions[false]"'
    else
      puts "  Total duplicate versions removed: #{total_duplicates_removed}"
    end
    puts '=' * 80
  end
end
