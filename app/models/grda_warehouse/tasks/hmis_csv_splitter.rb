###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# This class is used to split HMIS data into multiple file sets based on the project ids provided
# Run like so:
# splitter = GrdaWarehouse::Tasks::HmisCsvSplitter.new(source_path: '/path/to/source/data', destination_path: '/path/to/destination/data', project_ids: ['P-1', 'P-2', 'P-3'])
# splitter.run!

###  Checking the results:
# Process the results into some ruby arrays
### Run this regular expression against the lines that look like: "Added 229332 of 306428 rows to IncomeBenefits.csv"
# Pattern:
# `.+ (\d+) .+ (\d+) rows to (.+)`
# Replace with:
# `['$1', '$2', '$3',],`
#
# f.each.with_index do |(added, total, file), i|
#   s_added = s[i][0]
#   diff = total.to_i - added.to_i - s_added.to_i
#   puts "#{file}: missing: #{diff}"
# end

require 'csv'
require 'memery'
module GrdaWarehouse::Tasks
  class HmisCsvSplitter
    include Memery
    attr_accessor :errors, :project_ids, :enrollment_ids, :personal_ids, :export_id, :source_path, :destination_path, :organization_ids
    def initialize(source_path:, destination_path:, project_ids:)
      @source_path = source_path
      @destination_path = destination_path
      @project_ids = project_ids
      @organization_ids = Set.new
      @enrollment_ids = Set.new
      @personal_ids = Set.new
    end

    def run!
      return unless source_path.present? && File.directory?(source_path)

      Rails.logger.debug "Processing HMIS data from #{source_path}"
      # Copy Export.csv
      FileUtils.mkdir_p(destination_path)
      Rails.logger.debug 'Copying Export.csv'
      FileUtils.cp_r(File.join(source_path, 'Export.csv'), destination_path)
      Rails.logger.debug 'Copying User.csv'
      FileUtils.cp_r(File.join(source_path, 'User.csv'), destination_path)
      Rails.logger.debug 'Finding relevant organizations'
      capture_relevant_organization_ids
      Rails.logger.debug 'Finding relevant enrollment ids'
      capture_relevant_enrollment_ids

      HmisCsvTwentyTwentyTwo.importable_files_map.each_key do |filename|
        next if filename.in?(manually_processed)

        Rails.logger.debug "Splitting #{filename}"
        source_file_path = File.join(source_path, filename)
        destination_file_path = File.join(destination_path, filename)
        next unless File.exist?(source_file_path)

        added = 0
        original = 0
        ::CSV.open(destination_file_path, 'wb') do |output|
          ::CSV.foreach(source_file_path, **csv_options).each.with_index do |row, i|
            original += 1
            output << row.headers if i.zero? # Include the header
            # Add project limited
            if filename.in?(project_related)
              if row['ProjectID'].in?(project_ids)
                output << row
                added += 1
              end
            elsif filename == 'Organization.csv'
              if row['OrganizationID'].in?(organization_ids)
                output << row
                added += 1
              end
            elsif filename == 'Client.csv'
              if row['PersonalID'].in?(personal_ids)
                output << row
                added += 1
              end
            elsif row.key?('EnrollmentID')
              # Add enrollment limited
              output << row if row['EnrollmentID'].in?(enrollment_ids)
              added += 1
            else
              raise "Unknown file: #{filename}"
            end
          end
        end
        Rails.logger.debug "Added #{added} of #{original} rows to #{filename}"
      end
    end

    # Find relevant OrganizationIDs in Project.csv and make note
    private def capture_relevant_organization_ids
      ::CSV.foreach(File.join(source_path, 'Project.csv'), **csv_options).each do |row|
        next unless row['ProjectID'].in?(project_ids)

        organization_ids << row['OrganizationID']
      end
    end

    # Find relevant EnrollmentID and PersonalIDs in Enrollment.csv and make note
    private def capture_relevant_enrollment_ids
      ::CSV.foreach(File.join(source_path, 'Enrollment.csv'), **csv_options).each do |row|
        next unless row['ProjectID'].in?(project_ids)

        enrollment_ids << row['EnrollmentID']
        personal_ids << row['PersonalID']
      end
    end

    private def csv_options
      {
        headers: true,
        # header_converters: downcase_converter,
        liberal_parsing: true,
        encoding: 'iso-8859-1:utf-8',
      }
    end

    private def downcase_converter
      ->(header) { header.downcase }
    end

    private def manually_processed
      [
        'Export.csv',
        'User.csv',
      ]
    end

    private def project_related
      [
        'Project.csv',
        'Inventory.csv',
        'ProjectCoC.csv',
        'Affiliation.csv',
        'Funder.csv',
      ]
    end
  end
end
