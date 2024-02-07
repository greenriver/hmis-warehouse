###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudSpmReport::Fy2023
  class Episode < GrdaWarehouseBase
    self.table_name = 'hud_report_spm_episodes'
    include Detail

    belongs_to :client, class_name: 'GrdaWarehouse::Hud::Client'

    has_many :enrollment_links
    has_many :enrollments, through: :enrollment_links
    has_many :bed_nights

    has_many :hud_reports_universe_members, inverse_of: :universe_membership, class_name: 'HudReports::UniverseMember', foreign_key: :universe_membership_id

    attr_accessor :report # FIXME?
    attr_writer :filter

    def self.detail_headers
      client_columns = ['client_id', 'enrollment.first_name', 'enrollment.last_name', 'enrollment.personal_id']
      hidden_columns = ['id', 'report_instance_id'] + client_columns
      columns = client_columns + (column_names - hidden_columns)
      columns.map do |col|
        [col, header_label(col)]
      end.to_h
    end

    def enrollment
      enrollments.first
    end

    def compute_episode(enrollments, included_project_types:, excluded_project_types:, include_self_reported_and_ph:)
      raise 'Client undefined' unless client.present?

      calculated_bed_nights = candidate_bed_nights(enrollments, included_project_types, include_self_reported_and_ph)
      calculated_excluded_dates = excluded_bed_nights(enrollments, excluded_project_types)
      calculated_bed_nights.reject! { |_, _, date| date.in?(calculated_excluded_dates) }

      filtered_bed_nights = filter_episode(calculated_bed_nights)
      return unless filtered_bed_nights.present?

      bed_nights_array = []
      enrollment_links_array = []
      any_bed_nights_in_report_range = false
      filtered_bed_nights.each do |enrollment, service_id, date|
        bed_nights_array << BedNight.new(
          client_id: client.id,
          enrollment_id: enrollment.id,
          service_id: service_id,
          date: date,
        )
        any_bed_nights_in_report_range = true if date.between?(report_start_date, report_end_date)
      end

      enrollment_ids = filtered_bed_nights.map { |enrollment, _, _| enrollment.id }.uniq
      enrollment_ids.each do |enrollment_id|
        enrollment_links_array << EnrollmentLink.new(
          enrollment_id: enrollment_id,
        )
      end

      dates = filtered_bed_nights.map(&:last)
      assign_attributes(
        first_date: dates.first, # dates is sorted in filter_bed_nights, so first/last should be min/max
        last_date: dates.last,
        days_homeless: filtered_bed_nights.count,
        literally_homeless_at_entry: literally_homeless_at_entry(filtered_bed_nights, dates.first),
      )

      {
        episode: self,
        bed_nights: bed_nights_array,
        enrollment_links: enrollment_links_array,
        any_bed_nights_in_report_range: any_bed_nights_in_report_range,
      }
    end

    private def candidate_bed_nights(enrollments, project_types, include_self_reported_and_ph)
      bed_nights = {} # Hash with date as key so we only get one candidate per overlapping night
      enrollments = enrollments.select do |e|
        # For PH projects, only stays meeting the Identifying Clients Experiencing Literal Homelessness at Project Entry criteria are included in time experiencing homelessness.
        in_project_type = e.project_type.in?(project_types)
        # Always drop PH that wasn't literally homeless at entry
        # NOTE: PH is never in the project types, but included because of include_self_reported_and_ph
        if include_self_reported_and_ph && e.project_type.in?(HudUtility2024.project_type_number_from_code(:ph))
          enrollment_literally_homeless_at_entry(e)
        else
          in_project_type
        end
      end
      enrollments.each do |enrollment|
        if enrollment.project_type.in?(HudUtility2024.project_type_number_from_code(:es_nbn))
          # NbN only gets service nights in the report range
          bed_nights.merge!(
            enrollment.enrollment.services. # Preloaded
              # merge(GrdaWarehouse::Hud::Service.bed_night.between(start_date: report_start_date, end_date: report_end_date)).
              # pluck(s_t[:id], s_t[:record_type], s_t[:date_provided]).
              map do |service|
                date = service.date_provided
                next unless service.record_type == HudUtility2024.record_type('Bed Night', true) && date.between?(report_start_date, report_end_date)

                [enrollment, service.id, date]
              end.compact.group_by(&:last).
              transform_values { |v| Array.wrap(v).last }, # Unique by date
          )
        else
          # There are two output tables required for this measure.  Each of the two tables has two rows – each with a different universe of clients and corresponding universe of data.  Effectively, there is a single row of output which must be produced four different ways, each using a different universe of data, as shown below:
          #   •	Measure 1a / Metric 1:  Persons in ES-EE, ES-NbN, and SH – do not include data from element 3.917.
          #   •	Measure 1a / Metric 2:  Persons in ES-EE, ES-NbN, SH, and TH – do not include data from element 3.917.
          #   •	Measure 1b / Metric 1:  Persons in ES-EE, ES-NbN, SH, and PH – include data from element 3.917 and time between [project start date] and [housing move-in date].
          # •	Measure 1b / Metric 2:  Persons in ES-EE, ES-NbN, SH, TH, and PH – include data from element 3.917 and time between [project start date] and [housing move-in date].

          start_date = if include_self_reported_and_ph
            # Include self-reported dates, if any, otherwise later of project start and lookback date
            enrollment.start_of_homelessness || [enrollment.entry_date, lookback_date].max
          else
            enrollment.entry_date
          end
          end_date = if enrollment.project_type.in?(HudUtility2024.project_type_number_from_code(:ph))
            # PH only gets days before move-in, if there is one
            enrollment.move_in_date || enrollment.exit_date
          else
            enrollment.exit_date
          end
          # The exit day is not a bed-night
          end_date -= 1.day if end_date.present?
          # Don't include days after the end of the reporting period
          end_date = [end_date, report_end_date].compact.min
          (start_date .. end_date).map do |date|
            bed_nights[date] = [enrollment, nil, date]
          end
        end
      end

      bed_nights.values
    end

    private def excluded_bed_nights(enrollments, project_types)
      bed_nights = Set.new
      enrollments = enrollments.select { |e| e.project_type.in?(project_types) }
      enrollments.each do |enrollment|
        if enrollment.project_type.in?(HudUtility2024.project_type_number_from_code(:th))
          # TH bed nights are not considered homeless
          end_date = enrollment.exit_date || report_end_date
          bed_nights += (enrollment.entry_date .. end_date).to_a
        elsif enrollment.project_type.in?(HudUtility2024.project_type_number_from_code(:ph))
          # PH bed nights on or after move in are not considered homeless
          next unless enrollment.move_in_date.present?

          end_date = enrollment.exit_date || report_end_date
          bed_nights += (enrollment.move_in_date .. end_date).to_a
        else
          raise 'Unexpected project type, no exclusion rules'
        end
      end

      bed_nights
    end

    # @param bed_nights [[Enrollment, service_id, Date]] Array of candidate bed nights to be processed
    private def filter_episode(calculated_bed_nights)
      return unless calculated_bed_nights.present?

      calculated_bed_nights = calculated_bed_nights.sort_by(&:last)
      client_end_date = calculated_bed_nights.last.last
      client_start_date = client_end_date - 365.days

      # Include contiguous dates before the calculated client start date:
      # First, find as close to the start date as possible in the array
      index = 0
      index += 1 while calculated_bed_nights[index].last < client_start_date

      # Then walk back until there is a break
      index -= 1 while index > 1 && calculated_bed_nights[index - 1].last == calculated_bed_nights[index].last - 1.day

      # Finally, return the selected dates
      calculated_bed_nights[index ..].map
    end

    private def literally_homeless_at_entry(bed_nights, first_date)
      enrollment_literally_homeless_at_entry(bed_nights.detect { |_, _, date| date == first_date }.first)
    end

    private def enrollment_literally_homeless_at_entry(enrollment)
      return true if enrollment.project_type.in?([0, 1, 4, 8])

      enrollment.project_type.in?([2, 3, 9, 10, 13]) &&
        (enrollment.prior_living_situation.in?(100..199) ||
          (enrollment.previous_street_essh? && enrollment.prior_living_situation.in?(200..299) && enrollment.los_under_threshold?) ||
            (enrollment.previous_street_essh? && enrollment.prior_living_situation.in?(300..499) && enrollment.los_under_threshold?))
    end

    private def report_start_date
      filter.start
    end

    private def lookback_date
      report_start_date - 7.years
    end

    private def report_end_date
      filter.end
    end

    private def filter
      @filter ||= ::Filters::HudFilterBase.new(user_id: report.user.id).update(report.options)
    end
  end
end
