###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# Profiles a HUD HMIS CSV export to produce diagnostic metrics about scale,
# data quality, and distribution. Run offline by engineers via rake task.
#
# Usage: rails driver:hmis_csv_importer:profile[/path/to/export/dir]
#
# Outputs results to docs/research/hmis-csv-<ExportID>/
module HmisCsvImporter
  class CsvProfiler
    REQUIRED_FILES = ['Export.csv', 'Project.csv', 'Exit.csv', 'Client.csv', 'Enrollment.csv'].freeze

    PROJECT_TYPES = {
      0 => 'Emergency Shelter - Entry Exit',
      1 => 'Emergency Shelter - Night-by-Night',
      2 => 'Transitional Housing',
      3 => 'PH - Permanent Supportive Housing',
      4 => 'Street Outreach',
      6 => 'Services Only',
      7 => 'Other',
      8 => 'Safe Haven',
      9 => 'PH - Housing Only',
      10 => 'PH - Housing with Services',
      11 => 'Day Shelter',
      12 => 'Homelessness Prevention',
      13 => 'PH - Rapid Re-Housing',
      14 => 'Coordinated Entry',
    }.freeze

    DURATION_CUTOFF = 180
    TEMPORAL_CUTOFF = 365
    ENROLLMENT_COUNT_CUTOFF = 100
    HOUSEHOLD_OUTLIER_THRESHOLD = 10

    attr_reader :dir, :export, :results

    def initialize(dir)
      @dir = dir
      validate_files!
      @results = {}
    end

    def run
      load_export
      load_lookups # Pass 1: build project/exit/client indexes
      load_enrollments # Pass 2: stream enrollments and accumulate stats
      compute_finals   # Derive final metrics from accumulated data
      self
    end

    private

    # -------------------------------------------------------------------------
    # Validation
    # -------------------------------------------------------------------------

    def validate_files!
      missing = REQUIRED_FILES.reject { |f| File.exist?(File.join(dir, f)) }
      raise ArgumentError, "Missing required CSV files: #{missing.join(', ')}" if missing.any?
    end

    # -------------------------------------------------------------------------
    # Export metadata
    # -------------------------------------------------------------------------

    def load_export
      rows = []
      csv_foreach('Export.csv', headers: true) { |row| rows << row }

      raise ArgumentError, 'Export.csv must contain exactly one data row' if rows.size != 1

      row = rows.first
      @export = {
        export_id: row['ExportID'],
        source_id: row['SourceID'],
        export_start_date: parse_date(row['ExportStartDate']),
        export_end_date: parse_date(row['ExportEndDate']),
      }
    end

    def export_end_date
      @export[:export_end_date]
    end

    # -------------------------------------------------------------------------
    # Pass 1: build lookup tables
    # -------------------------------------------------------------------------

    def load_lookups
      load_projects
      load_exits
      load_clients
    end

    def load_projects
      @project_type_by_id = {}
      csv_foreach('Project.csv', headers: true) do |row|
        @project_type_by_id[row['ProjectID']] = row['ProjectType'].to_i
      end
    end

    def load_exits
      @exit_date_by_enrollment_id = {}
      csv_foreach('Exit.csv', headers: true) do |row|
        @exit_date_by_enrollment_id[row['EnrollmentID']] = parse_date(row['ExitDate'])
      end
    end

    def load_clients
      @total_client_count = 0
      ssn_tally = Hash.new(0)

      csv_foreach('Client.csv', headers: true) do |row|
        @total_client_count += 1
        ssn = row['SSN'].to_s.gsub(/\D/, '')
        ssn_tally[ssn] += 1 if HudUtility2026.valid_social?(ssn)
      end

      @duplicate_ssn_count = ssn_tally.count { |_, count| count > 1 }
    end

    # -------------------------------------------------------------------------
    # Pass 2: stream enrollments and accumulate accumulators
    # -------------------------------------------------------------------------

    def load_enrollments
      # Project-level accumulators
      @duration_hist_by_type = Hash.new { |h, k| h[k] = Hash.new(0) } # { project_type => { days => count } }
      @open_by_type          = Hash.new(0)
      @closed_by_type        = Hash.new(0)
      @clients_by_type       = Hash.new { |h, k| h[k] = Set.new }
      @enroll_count_by_proj  = Hash.new(0)                               # { project_id => count }
      @proj_type_by_proj_id  = {}                                        # { project_id => type } (populated as we go)
      @total_enrollment_count = 0

      # Temporal
      @entry_date_hist = Hash.new(0) # { days_ago_bucket => count }
      @entry_date_hist_by_type = Hash.new { |h, k| h[k] = Hash.new(0) } # { project_type => { days_ago_bucket => count } }

      # Household tally
      @household_size_tally = Hash.new(0) # { household_id => enrollment_count }

      # Client spans for overlap / duration / count distribution
      @spans_by_client = Hash.new { |h, k| h[k] = [] } # { personal_id => [[entry, effective_exit, duration, project_id], ...] }

      csv_foreach('Enrollment.csv', headers: true) do |row|
        enrollment_id = row['EnrollmentID']
        personal_id   = row['PersonalID']
        project_id    = row['ProjectID']
        household_id  = row['HouseholdID']
        entry_date    = parse_date(row['EntryDate'])

        next unless entry_date # skip rows with unparseable entry dates

        exit_date   = @exit_date_by_enrollment_id[enrollment_id]
        open_enroll = exit_date.nil?

        project_type = @project_type_by_id[project_id]
        @proj_type_by_proj_id[project_id] ||= project_type

        duration = enrollment_duration(entry_date, exit_date)
        effective_exit = open_enroll ? export_end_date : exit_date

        @total_enrollment_count += 1

        # Project aggregation [1a-1f]
        duration_bucket = [duration, DURATION_CUTOFF].min
        @duration_hist_by_type[project_type][duration_bucket] += 1
        open_enroll ? @open_by_type[project_type] += 1 : @closed_by_type[project_type] += 1
        @clients_by_type[project_type].add(personal_id)
        @enroll_count_by_proj[project_id] += 1

        # Temporal distribution [2a, 2c]
        days_ago = (export_end_date - entry_date).to_i
        days_ago_bucket = days_ago >= TEMPORAL_CUTOFF ? "#{TEMPORAL_CUTOFF}+" : days_ago
        @entry_date_hist[days_ago_bucket] += 1
        @entry_date_hist_by_type[project_type][days_ago_bucket] += 1

        # Household tally [4a]
        @household_size_tally[household_id] += 1

        # Client spans [3a, 5b, 5d, 5e]
        @spans_by_client[personal_id] << [entry_date, effective_exit, duration, project_id]
      end
    end

    # -------------------------------------------------------------------------
    # Final computations
    # -------------------------------------------------------------------------

    def compute_finals
      compute_project_stats
      compute_client_stats
      compute_overlap_count
      compute_household_distribution
      results[:entry_date_hist] = @entry_date_hist
      results[:entry_date_hist_by_type] = @entry_date_hist_by_type
      results[:proj_type_by_proj_id] = @proj_type_by_proj_id
    end

    def compute_project_stats
      all_types = (@duration_hist_by_type.keys + @open_by_type.keys + @closed_by_type.keys).uniq.sort

      results[:project_stats] = all_types.map do |type|
        open_count   = @open_by_type[type]
        closed_count = @closed_by_type[type]
        total        = open_count + closed_count
        unique_clients = @clients_by_type[type].size

        {
          project_type: type,
          project_type_label: PROJECT_TYPES[type] || "Unknown (#{type})",
          total_enrollments: total,
          pct_of_total_enrollments: percent(total, @total_enrollment_count),
          unique_clients: unique_clients,
          pct_of_total_clients: percent(unique_clients, @total_client_count),
          open_enrollments: open_count,
          closed_enrollments: closed_count,
          open_to_closed_ratio: closed_count.positive? ? (open_count.to_f / closed_count).round(3) : 'N/A (no closed)',
          duration_histogram: @duration_hist_by_type[type],
        }
      end

      results[:enrollments_per_project] = @enroll_count_by_proj.map do |proj_id, count|
        {
          project_id: proj_id,
          project_type: @proj_type_by_proj_id[proj_id],
          enrollment_count: count,
        }
      end.sort_by { |r| -r[:enrollment_count] }
    end

    def compute_client_stats
      enrollment_count_hist = Hash.new(0)
      duration_sum_hist     = Hash.new(0)

      @spans_by_client.each_value do |spans|
        count_bucket = [spans.size, ENROLLMENT_COUNT_CUTOFF].min
        enrollment_count_hist[count_bucket] += 1

        capped_durations_sum = spans.sum { |_, _, dur, _| [dur, DURATION_CUTOFF].min }
        duration_sum_hist[[capped_durations_sum, DURATION_CUTOFF].min] += 1
      end

      results[:client_stats] = {
        total_clients: @total_client_count,
        avg_enrollments_per_client: @total_client_count.positive? ? (@total_enrollment_count.to_f / @total_client_count).round(2) : 0,
        duplicate_ssn_count: @duplicate_ssn_count,
        enrollment_count_histogram: enrollment_count_hist,
        duration_sum_histogram: duration_sum_hist,
      }
    end

    def compute_overlap_count
      concurrent_client_count = 0
      overlap_by_project = Hash.new(0)

      @spans_by_client.each_value do |spans|
        next if spans.size < 2

        sorted = spans.sort_by { |entry, _, _, _| entry }
        max_end = sorted.first[1]
        overlapping_project_ids = Set.new

        sorted.each_with_index do |(entry, effective_exit, _, project_id), i|
          if i.positive? && entry < max_end
            overlapping_project_ids.add(project_id)
            # Also mark the earlier span(s) whose window caused the overlap.
            # Any span whose effective_exit > entry contributes to this overlap.
            sorted[0...i].each do |_prev_entry, prev_exit, _, prev_proj|
              overlapping_project_ids.add(prev_proj) if prev_exit > entry
            end
          end
          max_end = [max_end, effective_exit].max
        end

        if overlapping_project_ids.any?
          concurrent_client_count += 1
          overlapping_project_ids.each { |pid| overlap_by_project[pid] += 1 }
        end
      end

      results[:concurrent_enrollment_count] = concurrent_client_count
      results[:overlap_by_project] = overlap_by_project
    end

    def compute_household_distribution
      size_dist = Hash.new(0)
      @household_size_tally.each_value { |count| size_dist[count] += 1 }
      results[:household_size_distribution] = size_dist
    end

    # -------------------------------------------------------------------------
    # Helpers
    # -------------------------------------------------------------------------

    # Returns duration in days per plan spec:
    # - exit exists and exit != entry: exit_date - entry_date
    # - exit exists and exit == entry: 1
    # - no exit: DURATION_CUTOFF (180, the max bucket)
    def enrollment_duration(entry_date, exit_date)
      return DURATION_CUTOFF unless exit_date

      diff = (exit_date - entry_date).to_i
      diff.positive? ? diff : 1
    end

    def percent(numerator, denominator)
      return 0.0 if denominator.zero?

      (numerator.to_f / denominator * 100).round(2)
    end

    def parse_date(str)
      return nil if str.blank?

      Date.parse(str.to_s.strip.split(' ').first)
    rescue ArgumentError, TypeError
      nil
    end

    def csv_foreach(filename, **opts, &block)
      CSV.foreach(File.join(dir, filename), encoding: 'bom|utf-8', **opts, &block)
    end
  end
end
