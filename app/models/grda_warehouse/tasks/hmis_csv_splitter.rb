###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# Splits an HMIS CSV export into N importable file sets under destination_path/part_1 .. part_N,
# grouping projects so enrollment counts are roughly even across parts.
#
# Split everything into three balanced parts:
#   splitter = GrdaWarehouse::Tasks::HmisCsvSplitter.new(source_path: '/path/to/source', destination_path: '/path/to/destination', parts: 3)
#   splitter.run!
#
# Extract two projects into a single file set (written to destination/part_1):
#   GrdaWarehouse::Tasks::HmisCsvSplitter.new(source_path: '/path/to/source', destination_path: '/path/to/destination', project_ids: ['P-1', 'P-2'], parts: 1).run!
#
# Checking the results: each entry has the source row count, the rows written across all parts, and
# the per-part breakdown. With no project_ids filter, original - added is 0 for every file except
# Client.csv and Organization.csv.
# A client enrolled in projects that landed in different parts is written to each.
# An Organization with projects that landed in different parts is written to each.
#
# splitter.results.transform_values { |r| r[:original] - r[:added] }
#
# To confirm client and organization counts, the following should output the numbers in the initial files:
#
# destination_path = '/path/to/destination'
# %w[Organization.csv Client.csv].each do |filename|
#   column = filename == 'Client.csv' ? 'PersonalID' : 'OrganizationID'
#   ids = (1..5).flat_map do |i|
#     CSV.read(File.join(destination_path, "part_#{i}", filename), headers: true).map { |r| r[column] }
#   end
#   puts "#{filename}: #{ids.uniq.size} distinct ids across parts"
# end

require 'csv'

module GrdaWarehouse::Tasks
  class HmisCsvSplitter
    attr_reader :source_path, :destination_path, :parts, :project_ids, :include_unenrolled_clients, :results, :project_groups

    # project_ids: nil processes every project; an Array restricts the split to those projects and
    # drops rows for any other ProjectID, including enrollments whose project is not in Project.csv.
    def initialize(source_path:, destination_path:, parts: 1, project_ids: nil, include_unenrolled_clients: false)
      raise ArgumentError, "parts must be a positive Integer, got #{parts.inspect}" unless parts.is_a?(Integer) && parts.positive?

      @source_path = source_path
      @destination_path = destination_path
      @parts = parts
      @project_ids = project_ids
      @project_filter = project_ids&.to_set
      @include_unenrolled_clients = include_unenrolled_clients
      @results = {}
      @project_groups = []
      @part_for_project = {}
      @parts_for_organization = {}
      @part_for_enrollment = {}
      @parts_for_personal_id = {}
    end

    def run!
      return unless source_path.present? && File.directory?(source_path)

      Rails.logger.debug "Processing HMIS data from #{source_path}"
      build_routing_tables
      part_paths.each do |path|
        FileUtils.mkdir_p(path)
        manually_processed.each { |filename| FileUtils.cp(File.join(source_path, filename), path) }
      end

      HmisCsvTwentyTwentySix.importable_files_map.each_key do |filename|
        next if filename.in?(manually_processed)

        source_file_path = File.join(source_path, filename)
        unless File.exist?(source_file_path)
          Rails.logger.debug "Skipping #{filename}, does not exist in source path"
          next
        end

        Rails.logger.debug "Splitting #{filename}"
        split_file(filename, source_file_path)
        Rails.logger.debug "Added #{results[filename][:added]} of #{results[filename][:original]} rows to #{filename} by part: #{results[filename][:by_part]}"
      end
      results
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

    # Reads Project.csv once and Enrollment.csv twice: the first enrollment pass counts per project so
    # the projects can be balanced, the second assigns each enrollment and client to a part.
    private def build_routing_tables
      organization_by_project = {}
      counts = Hash.new(0)
      each_source_row(File.join(source_path, 'Project.csv')) do |row|
        next unless included_project?(row['ProjectID'])

        organization_by_project[row['ProjectID']] = row['OrganizationID']
        # Registers the key at 0 so projects with no enrollments still get a part.
        counts[row['ProjectID']] += 0
      end
      each_source_row(File.join(source_path, 'Enrollment.csv')) do |row|
        counts[row['ProjectID']] += 1 if included_project?(row['ProjectID'])
      end

      @project_groups = self.class.balance_projects(counts, parts)
      project_groups.each_with_index do |ids, part|
        ids.each do |project_id|
          @part_for_project[project_id] = part
          organization_id = organization_by_project[project_id]
          add_part(@parts_for_organization, organization_id, part) if organization_id
        end
      end

      enrolled_personal_ids = Set.new
      each_source_row(File.join(source_path, 'Enrollment.csv')) do |row|
        enrolled_personal_ids << row['PersonalID'] if include_unenrolled_clients
        part = @part_for_project[row['ProjectID']]
        next if part.nil?

        @part_for_enrollment[row['EnrollmentID']] = part
        add_part(@parts_for_personal_id, row['PersonalID'], part)
      end

      capture_unenrolled_clients(enrolled_personal_ids) if include_unenrolled_clients
    end

    # A client with no enrollment anywhere in the source, filter or not, is written to part 1 only.
    private def capture_unenrolled_clients(enrolled_personal_ids)
      each_source_row(File.join(source_path, 'Client.csv')) do |row|
        next if enrolled_personal_ids.include?(row['PersonalID'])

        add_part(@parts_for_personal_id, row['PersonalID'], 0)
      end
    end

    private def split_file(filename, source_file_path)
      results[filename] = { original: 0, added: 0, by_part: Array.new(parts, 0) }
      headers = source_headers(source_file_path)
      raise "Headers are blank for #{filename}" if headers.blank?

      outputs = part_paths.map { |path| ::CSV.open(File.join(path, filename), 'wb') }
      outputs.each { |output| output << headers }
      each_source_row(source_file_path) do |row|
        results[filename][:original] += 1
        target_parts(filename, row).each do |part|
          outputs[part] << row
          results[filename][:added] += 1
          results[filename][:by_part][part] += 1
        end
      end
    ensure
      outputs&.each(&:close)
    end

    private def target_parts(filename, row)
      if filename.in?(project_related)
        Array(@part_for_project[row['ProjectID']])
      elsif filename == 'Organization.csv'
        @parts_for_organization[row['OrganizationID']] || []
      elsif filename == 'Client.csv'
        @parts_for_personal_id[row['PersonalID']] || []
      else
        Array(@part_for_enrollment[row['EnrollmentID']])
      end
    end

    private def add_part(table, key, part)
      (table[key] ||= Set.new) << part
    end

    private def included_project?(project_id)
      @project_filter.nil? || @project_filter.include?(project_id)
    end

    private def part_paths
      @part_paths ||= (1..parts).map { |i| File.join(destination_path, "part_#{i}") }
    end

    # Headers can't come from the data rows; a source file may legitimately contain only a header
    # line, and the destination file still needs that header to be importable.
    private def source_headers(source_file_path)
      open_source_csv(source_file_path, headers: false, &:shift)
    end

    private def each_source_row(source_file_path, &block)
      open_source_csv(source_file_path) { |csv| csv.each(&block) }
    end

    # HMIS CSVs come in all sorts of encodings.
    # Detect the source's actual encoding (BOM or statistical) and eventually writes it out as UTF-8.
    private def open_source_csv(source_file_path, headers: true, &block)
      AutoEncodingCsv.open(source_file_path, headers: headers, liberal_parsing: true, &block)
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
