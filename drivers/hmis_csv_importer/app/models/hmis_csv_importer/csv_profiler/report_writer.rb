###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HmisCsvImporter
  class CsvProfiler
    class ReportWriter
      DURATION_CUTOFF           = HmisCsvImporter::CsvProfiler::DURATION_CUTOFF
      TEMPORAL_CUTOFF           = HmisCsvImporter::CsvProfiler::TEMPORAL_CUTOFF
      ENROLLMENT_CUTOFF         = HmisCsvImporter::CsvProfiler::ENROLLMENT_COUNT_CUTOFF
      HOUSEHOLD_OUTLIER_THRESHOLD = HmisCsvImporter::CsvProfiler::HOUSEHOLD_OUTLIER_THRESHOLD

      attr_reader :profiler, :output_dir

      def initialize(profiler, output_dir)
        @profiler   = profiler
        @output_dir = output_dir
      end

      def write
        FileUtils.mkdir_p(output_dir)
        write_report_md
        write_project_type_duration_csv
        write_enrollments_per_project_csv
        write_entry_date_distribution_csv
        write_household_size_distribution_csv
        write_client_enrollment_count_csv
        write_client_enrollment_duration_csv
        write_concurrent_enrollments_csv
      end

      private

      def export
        profiler.export
      end

      def results
        profiler.results
      end

      # -----------------------------------------------------------------------
      # report.md
      # -----------------------------------------------------------------------

      def write_report_md
        lines = [
          header_lines,
          section_1_lines,
          section_2_lines,
          section_3_lines,
          section_4_lines,
          section_5_lines,
          section_6_lines,
        ].reduce(:+)

        File.write(File.join(output_dir, 'report.md'), lines.join("\n"))
      end

      def header_lines
        [
          '# HMIS CSV Profile Report',
          '',
          "**Export ID:** #{export[:export_id]}",
          "**Export period:** #{export[:export_start_date]} - #{export[:export_end_date]}",
          '',
          '---',
        ]
      end

      def section_1_lines
        lines = [
          '',
          '## Section 1: Project Aggregation',
          '',
          '### [1b/1c/1d/1e] Enrollments by Project Type',
          '',
          '| Type | Label | Enrollments | % of Total | Unique Clients | % of Clients | Open | Closed | Open:Closed Ratio |',
          '|------|-------|-------------|------------|----------------|--------------|------|--------|-------------------|',
        ]

        results[:project_stats].each do |ps|
          lines << "| #{ps[:project_type]} | #{ps[:project_type_label]} | #{ps[:total_enrollments]} | #{ps[:pct_of_total_enrollments]}% | #{ps[:unique_clients]} | #{ps[:pct_of_total_clients]}% | #{ps[:open_enrollments]} | #{ps[:closed_enrollments]} | #{ps[:open_to_closed_ratio]} |"
        end

        lines + [
          '',
          '_Duration histogram per project type written to `project_type_duration.csv`_',
          '',
          '### [1f] Enrollments per Project',
          '',
          "_Written to `enrollments_per_project.csv` — #{results[:enrollments_per_project].size} projects total_",
          '',
        ]
      end

      def section_2_lines
        lines = [
          '---',
          '',
          '## Section 2: Temporal Distribution',
          '',
          '### [2a] Enrollment Entry Date Distribution',
          '',
          "_Days between entry date and export end date. Entries older than #{TEMPORAL_CUTOFF} days are grouped into a single bucket._",
          '',
          '_Written to `entry_date_distribution.csv`_',
          '',
          '### [2c] Entry Date Age by Project Type',
          '',
          "_Percentage of each project type's enrollments with an entry date older than #{TEMPORAL_CUTOFF} days before the export end date._",
          '',
          '| Type | Label | Total Entries | % Entries 365+ Days Old |',
          '|------|-------|---------------|-------------------------|',
        ]

        results[:entry_date_hist_by_type].sort_by(&:first).each do |type, hist|
          total    = hist.values.sum
          aged     = hist["#{TEMPORAL_CUTOFF}+"].to_i
          aged_pct = total.positive? ? (aged.to_f / total * 100).round(2) : 0.0
          label    = HmisCsvImporter::CsvProfiler::PROJECT_TYPES[type] || "Unknown (#{type})"
          lines << "| #{type} | #{label} | #{total} | #{aged_pct}% |"
        end

        lines << ''
        lines
      end

      def section_3_lines
        client_stats   = results[:client_stats]
        concurrent_pct = client_stats[:total_clients].positive? ? (results[:concurrent_enrollment_count].to_f / client_stats[:total_clients] * 100).round(2) : 0

        [
          '---',
          '',
          '## Section 3: Concurrent Enrollments',
          '',
          '### [3a] Clients with Concurrent Enrollments',
          '',
          "Clients enrolled in 2+ projects with overlapping date ranges: **#{results[:concurrent_enrollment_count]}**",
          '',
          "That is **#{concurrent_pct}%** of all clients.",
          '',
          '_Detail by project written to `concurrent_enrollments.csv`_',
          '',
        ]
      end

      def section_4_lines
        dist     = results[:household_size_distribution].sort_by(&:first)
        outliers = dist.select { |size, _| size >= HOUSEHOLD_OUTLIER_THRESHOLD }

        lines = [
          '---',
          '',
          '## Section 4: Household Aggregation',
          '',
          '### [4a] Household Size Distribution',
          '',
          '_Written to `household_size_distribution.csv`_',
          '',
          '| Household Size | Count |',
          '|----------------|-------|',
        ]

        dist.first(10).each { |size, count| lines << "| #{size} | #{count} |" }
        lines << '| ... | ... |' if dist.size > 10
        lines << ''

        if outliers.any?
          outlier_count = outliers.sum(&:last)
          largest       = outliers.map(&:first).max
          lines << "_Households with #{HOUSEHOLD_OUTLIER_THRESHOLD}+ members: **#{outlier_count}** (largest: #{largest} members)._"
          lines << ''
        end

        lines
      end

      def section_5_lines
        client_stats = results[:client_stats]

        [
          '---',
          '',
          '## Section 5: Client Aggregation',
          '',
          '### [5a] Total Unique Clients',
          '',
          "**#{client_stats[:total_clients]}**",
          '',
          '### [5b] Average Enrollments per Client',
          '',
          "**#{client_stats[:avg_enrollments_per_client]}**",
          '',
          '### [5c] Possible Duplicate Client Records (by SSN)',
          '',
          "Clients with a valid SSN that appears on 2+ client records: **#{client_stats[:duplicate_ssn_count]}**",
          '',
          '### [5d] Client Enrollment Count Distribution',
          '',
          "_Written to `client_enrollment_count.csv` — counts capped at #{ENROLLMENT_CUTOFF}+_",
          '',
          '### [5e] Client Cumulative Enrollment Duration Distribution',
          '',
          "_Written to `client_enrollment_duration.csv` — total days capped at #{DURATION_CUTOFF}+_",
          '',
        ]
      end

      def section_6_lines
        total_enrollments = results[:project_stats].sum { |ps| ps[:total_enrollments] }
        total_exits       = results[:project_stats].sum { |ps| ps[:closed_enrollments] }
        exit_pct          = total_enrollments.positive? ? (total_exits.to_f / total_enrollments * 100).round(2) : 0

        [
          '---',
          '',
          '## Section 6: Global Data Quality',
          '',
          '### [6a] Enrollment-to-Exit Ratio',
          '',
          "- Total enrollments: **#{total_enrollments}**",
          "- Enrollments with an exit record: **#{total_exits}** (#{exit_pct}%)",
          "- Open enrollments (no exit): **#{total_enrollments - total_exits}** (#{(100 - exit_pct).round(2)}%)",
          '',
        ]
      end

      # -----------------------------------------------------------------------
      # CSVs
      # -----------------------------------------------------------------------

      def write_project_type_duration_csv
        CSV.open(File.join(output_dir, 'project_type_duration.csv'), 'w') do |csv|
          csv << ['project_type', 'duration_days', 'enrollment_count']
          results[:project_stats].each do |ps|
            sorted_hist = ps[:duration_histogram].sort_by do |days, _|
              days == DURATION_CUTOFF ? DURATION_CUTOFF + 1 : days
            end
            sorted_hist.each do |days, count|
              label = days >= DURATION_CUTOFF ? "#{DURATION_CUTOFF}+" : days.to_s
              csv << [ps[:project_type], label, count]
            end
          end
        end
      end

      def write_enrollments_per_project_csv
        CSV.open(File.join(output_dir, 'enrollments_per_project.csv'), 'w') do |csv|
          csv << ['project_id', 'project_type', 'enrollment_count']
          results[:enrollments_per_project].each do |r|
            csv << [r[:project_id], r[:project_type], r[:enrollment_count]]
          end
        end
      end

      def write_entry_date_distribution_csv
        CSV.open(File.join(output_dir, 'entry_date_distribution.csv'), 'w') do |csv|
          csv << ['days_ago', 'enrollment_count']
          sorted = results[:entry_date_hist].sort_by do |days_ago, _|
            days_ago == "#{TEMPORAL_CUTOFF}+" ? TEMPORAL_CUTOFF + 1 : days_ago.to_i
          end
          sorted.each { |days_ago, count| csv << [days_ago, count] }
        end
      end

      def write_household_size_distribution_csv
        CSV.open(File.join(output_dir, 'household_size_distribution.csv'), 'w') do |csv|
          csv << ['household_size', 'household_count']
          results[:household_size_distribution].sort_by(&:first).each { |size, count| csv << [size, count] }
        end
      end

      def write_client_enrollment_count_csv
        CSV.open(File.join(output_dir, 'client_enrollment_count.csv'), 'w') do |csv|
          csv << ['enrollment_count', 'client_count']
          sorted = results[:client_stats][:enrollment_count_histogram].sort_by do |count, _|
            count == ENROLLMENT_CUTOFF ? ENROLLMENT_CUTOFF + 1 : count
          end
          sorted.each do |count, client_count|
            label = count >= ENROLLMENT_CUTOFF ? "#{ENROLLMENT_CUTOFF}+" : count.to_s
            csv << [label, client_count]
          end
        end
      end

      def write_client_enrollment_duration_csv
        CSV.open(File.join(output_dir, 'client_enrollment_duration.csv'), 'w') do |csv|
          csv << ['days', 'client_count']
          sorted = results[:client_stats][:duration_sum_histogram].sort_by do |days, _|
            days == DURATION_CUTOFF ? DURATION_CUTOFF + 1 : days
          end
          sorted.each do |days, count|
            label = days >= DURATION_CUTOFF ? "#{DURATION_CUTOFF}+" : days.to_s
            csv << [label, count]
          end
        end
      end

      def write_concurrent_enrollments_csv
        proj_type = results[:proj_type_by_proj_id]
        CSV.open(File.join(output_dir, 'concurrent_enrollments.csv'), 'w') do |csv|
          csv << ['project_id', 'project_type', 'overlap_client_count']
          results[:overlap_by_project].
            sort_by { |_, count| -count }.
            each { |project_id, count| csv << [project_id, proj_type[project_id], count] }
        end
      end
    end
  end
end
