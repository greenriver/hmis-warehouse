###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudSpmReport::Fy2023
  class Episode < GrdaWarehouseBase
    self.table_name = 'hud_report_spm_episodes'
    belongs_to :client, class_name: 'GrdaWarehouse::Hud::Client'

    has_many :enrollment_links
    has_many :enrollments, through: :enrollment_links
    has_many :bed_nights

    attr_accessor :report # FIXME?

    def compute_episode(included_project_types, excluded_project_types)
      raise 'Client undefined' unless client.present?

      enrollments = report.spm_enrollments.where(client_id: client.id)
      calculated_bed_nights = candidate_bed_nights(enrollments, included_project_types)
      calculated_excluded_dates = excluded_bed_nights(enrollments, excluded_project_types)
      calculated_bed_nights.reject! { |_, _, date| date.in?(calculated_excluded_dates) }
      calculated_bed_nights.sort_by!(&:last)

      filtered_bed_nights = filter_episode(calculated_bed_nights)

      BedNight.import!(filtered_bed_nights.map do |enrollment, service_id, date|
        bed_nights.build(
          client_id: client.id,
          enrollment_id: enrollment.id,
          service_id: service_id,
          date: date,
        )
      end)

      enrollment_ids = bed_nights.map(&:enrollment_id).uniq
      EnrollmentLink.import!(enrollment_ids.map do |enrollment_id|
        enrollment_links.build(
          enrollment_id: enrollment_id,
        )
      end)

      dates = filtered_bed_nights.map(&:last)
      first_date = dates.min
      update(
        first_date: first_date,
        last_date: dates.max,
        days_homeless: calculated_bed_nights.count,
        literally_homeless_at_entry: literally_homeless_at_entry(filtered_bed_nights, first_date),
      )
    end

    private def candidate_bed_nights(enrollments, project_types)
      bed_nights = {} # Hash with date as key so we only get one candidate per overlapping night
      enrollments = enrollments.where(project_type: project_types).preload(enrollment: :services)
      enrollments.each do |enrollment|
        if enrollment.project_type.in?(HudUtility2024.project_type_number_from_code(:es_nbn))
          # NbN only gets service nights in the report range
          bed_nights.merge!(
            enrollment.enrollment.
              services.merge(GrdaWarehouse::Hud::Service.bed_night.between(start_date: report_start_date, end_date: report_end_date)).
              pluck(s_t[:id], s_t[:date_provided]).map do |service_id, date|
                [enrollment, service_id, date]
              end.group_by(&:last), # Unique by date
          )
        else
          start_date = if enrollment.project_type.in?(HudUtility2024.project_type_number_from_code(:ph))
            # PH includes self-reported dates, if any, otherwise later of project start and lookback date
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
      enrollments = enrollments.where(project_type: project_types)
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

    private def filter_episode(bed_nights)
      # TODO

      bed_nights
    end

    private def literally_homeless_at_entry(bed_nights, first_date)
      enrollment = bed_nights.detect { |_, _, date| date == first_date }.first
      return true if enrollment.project_type.in?([0, 1, 4, 8])

      enrollment.project_type.in?([2, 3, 9, 10, 13]) &&
        (enrollment.prior_living_situation.in?(100..199) ||
          (enrollment.previous_street_essh? &&
            (enrollment.prior_living_situation.in?(200..299) && enrollment.length_of_stay.in?([2, 3])) ||
            (enrollment.prior_living_situation.in?(300..499) && enrollment.los_under_threshold?)))
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
      @filter ||= ::Filters::HudFilterBase.new(user_id: User.system_user.id).update(report.options)
    end
  end
end
