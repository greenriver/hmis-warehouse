###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# This class is used to split HMIS data into multiple file sets based on the project ids provided
# Run like so:
# splitter = GrdaWarehouse::Tasks::HmisCsvSplitter.new(source_path: '/path/to/source/data', destination_path: '/path/to/destination/data', project_ids: ['P-1', 'P-2', 'P-3'])
# splitter.run!
#
# To split into N parts with roughly even enrollment counts (writes destination/part_1 .. part_N):
# splitters = GrdaWarehouse::Tasks::HmisCsvSplitter.split_evenly(source_path: '/path/to/source/data', destination_path: '/path/to/destination', parts: 3)
# splitters.sum { |s| s.results['Enrollment.csv'][:added] } # should equal splitters.first.results['Enrollment.csv'][:original]

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

    # Splits the source into `parts` file sets under destination_path/part_1 .. part_N, grouping
    # projects so enrollment counts are roughly even across parts. Unenrolled clients, when
    # requested, are written to part_1 only so no Client.csv row appears in more than one part.
    # Returns the splitters, one per part, after each has run.
    def self.split_evenly(source_path:, destination_path:, parts:, include_unenrolled_clients: false)
      raise ArgumentError, "parts must be a positive Integer, got #{parts.inspect}" unless parts.is_a?(Integer) && parts.positive?

      groups = balance_projects(project_enrollment_counts(source_path), parts)
      groups.each_with_index.map do |project_ids, index|
        splitter = new(
          source_path: source_path,
          destination_path: File.join(destination_path, "part_#{index + 1}"),
          project_ids: project_ids,
          include_unenrolled_clients: include_unenrolled_clients && index.zero?,
        )
        splitter.run!
        splitter
      end
    end

    # Greedy longest-processing-time assignment: largest project first, each into the part
    # with the smallest running enrollment total. Ties fall to the part with fewer projects,
    # then the lower index, so equal inputs always produce the same grouping.
    def self.balance_projects(enrollment_counts, parts)
      buckets = Array.new(parts) { { total: 0, project_ids: [] } }
      ordered = enrollment_counts.sort_by { |project_id, count| [-count, project_id] }
      ordered.each do |project_id, count|
        bucket = buckets.each_with_index.min_by { |b, i| [b[:total], b[:project_ids].size, i] }.first
        bucket[:project_ids] << project_id
        bucket[:total] += count
      end
      buckets.map { |b| b[:project_ids] }
    end

    def self.project_enrollment_counts(source_path)
      counts = Hash.new(0)
      each_source_row(File.join(source_path, 'Project.csv')) do |row|
        # Registers the key at 0 so projects with no enrollments still appear in the hash.
        counts[row['ProjectID']] += 0
      end
      each_source_row(File.join(source_path, 'Enrollment.csv')) do |row|
        counts[row['ProjectID']] += 1
      end
      counts
    end

    def self.each_source_row(source_file_path, &block)
      open_source_csv(source_file_path) { |csv| csv.each(&block) }
    end

    # HMIS CSVs come in all sorts of encodings.
    # Detect the source's actual encoding (BOM or statistical) and eventually writes it out as UTF-8.
    def self.open_source_csv(source_file_path, headers: true, &block)
      AutoEncodingCsv.open(source_file_path, headers: headers, liberal_parsing: true, &block)
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

      HmisCsvTwentyTwentySix.importable_files_map.each_key do |filename|
        next if filename.in?(manually_processed)

        Rails.logger.debug "Splitting #{filename}"
        source_file_path = File.join(source_path, filename)
        destination_file_path = File.join(destination_path, filename)
        unless File.exist?(source_file_path)
          Rails.logger.debug "Skipping #{filename}, does not exist in source path"
          next
        end

        results[filename] = { added: 0, original: 0 }
        headers = source_headers(source_file_path)
        raise "Headers are blank for #{filename}" if headers.blank?

        ::CSV.open(destination_file_path, 'wb') do |output|
          output << headers
          each_source_row(source_file_path) do |row|
            results[filename][:original] += 1
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
              if row['EnrollmentID'].in?(enrollment_ids)
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
      each_source_row(File.join(source_path, 'Project.csv')) do |row|
        next unless row['ProjectID'].in?(project_ids)

        organization_ids << row['OrganizationID']
      end
    end

    # Find relevant EnrollmentID and PersonalIDs in Enrollment.csv and make note
    private def capture_relevant_enrollment_ids
      each_source_row(File.join(source_path, 'Enrollment.csv')) do |row|
        next unless row['ProjectID'].in?(project_ids)

        enrollment_ids << row['EnrollmentID']
        personal_ids << row['PersonalID']
      end
    end

    private def capture_unenrolled_clients
      all_enrolled_clients = Set.new
      each_source_row(File.join(source_path, 'Enrollment.csv')) do |row|
        all_enrolled_clients.add(row['PersonalID'])
      end

      each_source_row(File.join(source_path, 'Client.csv')) do |row|
        next if all_enrolled_clients.include?(row['PersonalID'])

        unenrolled_clients_personal_ids.add(row['PersonalID'])
      end
    end

    # Headers can't come from the data rows; a source file may legitimately contain only a header
    # line, and the destination file still needs that header to be importable.
    private def source_headers(source_file_path)
      open_source_csv(source_file_path, headers: false, &:shift)
    end

    private def each_source_row(source_file_path, &block)
      self.class.each_source_row(source_file_path, &block)
    end

    private def open_source_csv(source_file_path, headers: true, &block)
      self.class.open_source_csv(source_file_path, headers: headers, &block)
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
        'HMISParticipation.csv',
        'CEParticipation.csv',
      ]
    end
  end
end
