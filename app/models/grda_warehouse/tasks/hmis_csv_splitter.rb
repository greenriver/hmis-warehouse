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
### if you split the file into two and ran `splitter` and `splitter2`
# missing = {}
# splitter.results.each do |filename, result|
#   missing[filename] = {}
#   processed_count = splitter.results[filename][:added] + splitter2.results[filename][:added]
#   missing[filename][:missing] = result[:original] - processed_count
#   missing[filename][:original] = result[:original]
# end
# missing
### NOTE: negative numbers mean they were in both files

require 'csv'
require 'memery'
module GrdaWarehouse::Tasks
  class HmisCsvSplitter
    include Memery
    attr_accessor :project_ids, :enrollment_ids, :personal_ids, :export_id, :source_path, :destination_path, :organization_ids, :results, :unenrolled_clients_personal_ids, :include_unenrolled_clients
    def initialize(source_path:, destination_path:, project_ids:, include_unenrolled_clients: false)
      @source_path = source_path
      @destination_path = destination_path
      @project_ids = project_ids
      @organization_ids = Set.new
      @enrollment_ids = Set.new
      @personal_ids = Set.new
      @unenrolled_clients_personal_ids = Set.new
      @results = {}
      self.include_unenrolled_clients = include_unenrolled_clients
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
      if include_unenrolled_clients
        Rails.logger.debug 'Finding unenrolled clients'
        capture_unenrolled_clients
        Rails.logger.debug "Found #{unenrolled_clients_personal_ids.size} unenrolled clients"
      end

      HmisCsvTwentyTwentyTwo.importable_files_map.each_key do |filename|
        next if filename.in?(manually_processed)

        Rails.logger.debug "Splitting #{filename}"
        source_file_path = File.join(source_path, filename)
        destination_file_path = File.join(destination_path, filename)
        next unless File.exist?(source_file_path)

        results[filename] = { added: 0, original: 0 }
        ::CSV.open(destination_file_path, 'wb') do |output|
          ::CSV.foreach(source_file_path, **csv_options).each.with_index do |row, i|
            results[filename][:original] += 1
            output << row.headers if i.zero? # Include the header
            # Add project limited
            if filename.in?(project_related)
              if row['ProjectID'].in?(project_ids)
                output << row
                results[filename][:added] += 1
              end
            elsif filename == 'Organization.csv'
              if row['OrganizationID'].in?(organization_ids)
                output << row
                results[filename][:added] += 1
              end
            elsif filename == 'Client.csv'
              if row['PersonalID'].in?(personal_ids) || row['PersonalID'].in?(unenrolled_clients_personal_ids)
                output << row
                results[filename][:added] += 1
              end
            else
              # Add enrollment limited
              if row['EnrollmentID'].in?(enrollment_ids) # rubocop:disable Style/IfInsideElse
                output << row
                results[filename][:added] += 1
              end
            end
          end
        end
        Rails.logger.debug "Added #{results[filename][:added]} of #{results[filename][:original]} rows to #{filename}"
      end
      results
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

    # we need to get clients enrolled in CE, thats really the thing.
    private def capture_unenrolled_clients
      all_enrolled_clients = Set.new
      ::CSV.foreach(File.join(source_path, 'Enrollment.csv'), **csv_options).each do |row|
        # next if row['ProjectID'] == '1234'

        all_enrolled_clients.add(row['PersonalID'])
      end

      ::CSV.foreach(File.join(source_path, 'Client.csv'), **csv_options).each do |row|
        next if all_enrolled_clients.include?(row['PersonalID'])

        unenrolled_clients_personal_ids.add(row['PersonalID'])
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
