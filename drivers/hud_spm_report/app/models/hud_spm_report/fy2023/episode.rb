###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
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
    attr_writer :filter, :services

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

    # TODO: convert include_self_reported_and_ph to include_self_report_from_project_types so we can be explicit about which types we want to use when looking for time prior to entry
    def compute_episode(enrollments, included_project_types:, excluded_project_types:, include_self_reported_and_ph:)
      raise 'Client undefined' unless client.present?

      calculated_bed_nights = candidate_bed_nights(enrollments, included_project_types, include_self_reported_and_ph)
      excluded_dates = excluded_bed_nights(enrollments, excluded_project_types)
      allowed_bed_nights = calculated_bed_nights.reject { |_, _, date| date.in?(excluded_dates) }

      # when including 3.917 add days before entry from PH projects where entry was from a literally homeless situation
      # Step 1
      # c.	Measure 1b:  In addition to the clients identified in a) and b) above, lines 1 and 2 in measure 1b include clients experiencing homelessness in a permanent housing project (project types 3, 9, 10, and 13) during the report year. These stays are defined as those active in any permanent housing project where all of the following are true:
      # The stay meets the Identifying Clients Experiencing Literal Homelessness at Project Entry criteria
      # And (
      # ( [project start date] >= [report start date] and [project start date] <= [report end date] )
      # Or
      # ( [housing move-in date] >= [report start date] and [housing move-in date] <= [report end date] )
      # Or
      # ( [housing move-in date] is null and [project exit date] >= [report start date] and [project exit date] <= [report end date])
      pre_entry_inclusion_dates = if include_self_reported_and_ph
        ph_enrollments = enrollments.select { |enrollment, _, _| enrollment.project_type.in?(HudUtility2024.project_type_number_from_code(:ph)) }
        add_self_reported([], ph_enrollments).reject { |_, _, date| date.in?(excluded_dates) }
      else
        # when not including 3.917
        []
      end
      # To be included, in both 1a and 1b you need a homeless enrollment overlapping the range

      # Step 1
      inclusion_dates = allowed_bed_nights
      # 1b additionally checks time before entry for PH projects
      inclusion_dates += pre_entry_inclusion_dates
      # Throw out any with overlapping housed status
      # This actually happened above, so we don't need to do this
      # inclusion_dates.reject! { |_, _, date| date.in?(excluded_dates) }
      # Step 2 D
      # binding.pry if client.PersonalID.to_s == '644272'
      return unless inclusion_dates.present?

      # Steps 3 and 4
      filtered_bed_nights = filter_episode(allowed_bed_nights) || []
      # step 5
      # 5.	Measure 1b:  For each relevant project stay the client’s response to Data Standards element 3.917.3 –  Approximate date this episode of homelessness started – also represents time the client has experienced homelessness.
      # Including pre-entry for homeless enrollments
      # when including 3.917 add days before entry
      pre_entry_dates = if include_self_reported_and_ph
        add_self_reported([], enrollments).reject { |_, _, date| date.in?(excluded_dates) }
      else
        # when not including 3.917
        []
      end
      filtered_bed_nights += pre_entry_dates
      return unless filtered_bed_nights.present?

      bed_nights_array = []
      enrollment_links_array = []
      any_bed_nights_in_report_range = filtered_bed_nights.any? { |_, _, date| date.between?(report_start_date, report_end_date) }
      # any_bed_nights_in_report_range = false
      # filtered_bed_nights.each do |enrollment, service_id, date|
      #   bed_nights_array << BedNight.new(
      #     client_id: client.id,
      #     enrollment_id: enrollment.id,
      #     service_id: service_id,
      #     date: date,
      #   )
      #   any_bed_nights_in_report_range = true if date.between?(report_start_date, report_end_date)
      # end

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
        # Always drop PH that wasn't literally homeless at entry or not in report range
        # NOTE: PH is never in the project types, but included because of include_self_reported_and_ph
        if include_self_reported_and_ph && e.project_type.in?(HudUtility2024.project_type_number_from_code(:ph))
          enrollment_literally_homeless_at_entry(e) && include_ph_enrollment?(e)
        else
          in_project_type
        end
      end
      enrollments.each do |enrollment|
        if enrollment.project_type.in?(HudUtility2024.project_type_number_from_code(:es_nbn))
          next unless enrollment.enrollment.present? # Skip if the enrollment has disappeared (e.g., a concurrent import deleted it)

          # NbN only gets service nights in the report range and within the enrollment period
          first_night = [report_start_date, enrollment.entry_date].max
          last_night = if enrollment.exit_date.present?
            [enrollment.exit_date - 1.day, report_end_date].min # Cannot have an bed night on the exit date
          else
            report_end_date # If no exit, cannot have a bed night after the report period
          end

          # services shape `{ [EnrollmentID, PersonalID, data_source_id] => [2022-01-01, 2022-01-02] }`
          # services are already filtered to bed nights
          enrollment_services = @services[[enrollment.enrollment.EnrollmentID, enrollment.personal_id, enrollment.data_source_id]]
          next bed_nights unless enrollment_services.present?

          bed_nights.merge!(
            enrollment_services.
              map.with_index do |date, i|
                next unless date.between?(first_night, last_night)

                # return a triple [enrollment, id, date], using the index in place of the id so we don't need to load
                # it from the DB (middle item needs to be unique within the enrollment)
                [enrollment, i, date]
              end.compact.group_by(&:last).
              transform_values { |v| Array.wrap(v).last }, # Unique by date
          )
        else
          start_date = enrollment.entry_date
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
          # The exit day, if present, is not a a bed night
          end_date = if enrollment.exit_date
            [enrollment.exit_date - 1.day, report_end_date].min
          else
            report_end_date
          end
          bed_nights += (enrollment.entry_date .. end_date).to_a
        elsif enrollment.project_type.in?(HudUtility2024.project_type_number_from_code(:ph))
          # PH bed nights on or after move in are not considered homeless
          next unless enrollment.move_in_date.present?

          # The exit day, if present, is not a a bed night
          end_date = if enrollment.exit_date
            [enrollment.exit_date - 1.day, report_end_date].min
          else
            report_end_date
          end
          bed_nights += (enrollment.move_in_date .. end_date).to_a
        else
          raise 'Unexpected project type, no exclusion rules'
        end
      end

      bed_nights
    end

    private def add_self_reported(existing_bed_nights, enrollments)
      bed_nights = existing_bed_nights.index_by(&:last)
      enrollments.each do |enrollment|
        if enrollment.project_type.in?(HudUtility2024.project_type_number_from_code(:es_nbn))
          # NbN only gets service nights in the report range and within the enrollment period
          first_night = [report_start_date, enrollment.entry_date].max
          last_night = if enrollment.exit_date.present?
            [enrollment.exit_date - 1.day, report_end_date].min # Cannot have an bed night on the exit date
          else
            report_end_date # If no exit, cannot have a bed night after the report period
          end
          # services shape `{ [EnrollmentID, PersonalID, data_source_id] => [2022-01-01, 2022-01-02] }`
          # services are already filtered to bed nights
          enrollment_services = @services[[enrollment.enrollment.EnrollmentID, enrollment.personal_id, enrollment.data_source_id]]
          next unless enrollment_services.present?

          earliest_bed_night = enrollment_services.select do |date|
            date.between?(first_night, last_night)
          end.min
          next unless earliest_bed_night.present?

          # Self-reported dates earlier than the first bed night if present and the first bed night is on or after the lookback date
          start_date = [enrollment.start_of_homelessness, earliest_bed_night].compact.min
          # b.	For night-by-night based shelter stays, determine the client’s [earliest bed night] dated >= [project start date] and <= [project exit date].  If [earliest bed night] >= [lookback stop date], then every night from [approximate date this episode of homelessness started] up to and including [earliest bed night] should also be considered nights experiencing homelessness. For example, a response of “9/16/2022” with the client’s earliest bed night of 11/15/2022 would effectively include bed nights for 9/16/2022, 9/17/2022, 9/18/2022… up to and including 11/15/2022.  Naturally this does not mean the client was physically present at this specific shelter on these nights, but these dates are nonetheless included in the client’s total time experiencing homelessness.
          next unless earliest_bed_night >= lookback_date && start_date < enrollment.entry_date

          (start_date .. earliest_bed_night).map do |date|
            bed_nights[date] ||= [enrollment, nil, date] # Add the day if not already present
          end
        else
          # Self-reported dates earlier than the entry date if present and the **project** start is on or after the lookback date
          start_date = [enrollment.start_of_homelessness, enrollment.entry_date].compact.min
          # a.	For entry-exit based project stays, if the [project start date] is >= [lookback stop date], then every night from [approximate date this episode of homelessness started] up to and including [project start date] should also be considered nights experiencing homelessness, even if response in [approximate date this episode of homelessness started] extends prior to [lookback stop date].  For example, a response in [approximate date this episode of homelessness started] of “2/14/2022” with a [project start date] of 5/15/2022 would cause every night from 2/14/2022 through and including 5/15/2022 to be included in the client’s dataset of nights experiencing homelessness.
          next unless enrollment.entry_date >= lookback_date && start_date < enrollment.entry_date

          (start_date .. enrollment.entry_date).map do |date|
            bed_nights[date] ||= [enrollment, nil, date] # Add the day if not already present
          end
        end
      end

      bed_nights.values
    end

    # 3.	Utilizing data selected in step 1 and modified in step 2, determine each client’s latest homeless bed night which is >= [report start date] and <= [report end date].  This date becomes that particular client’s [client end date].
    #   a.	This date should be no later than the end date of the report ([client end date] must be <= [report end date]), in the event a project stay extends past the [report end date].
    #   b.	For enrollments in entry exit emergency shelters, this date should be one day prior to the client’s exit date, or the [report end date], whichever is earlier.  It cannot be the client’s exit date since that date does not represent a bed night.
    #   c.	For enrollments in night-by-night emergency shelters, this date must be based on recorded bed nights and not on the client’s start or exit date.
    #   d.	Measure 1b: Be sure not to include the [housing move-in date] itself, as this date does not represent a night experiencing homelessness.
    # 4.	For each active client, create a [client start date] which is 365 days prior to the [client end date] going back no further than the [lookback stop date].
    #   a.	[Client start date] = [client end date] – 365 days.
    #   b.	A [client start date] will usually be prior to the [report start date].
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
      index -= 1 while index.positive? && calculated_bed_nights[index - 1].last == calculated_bed_nights[index].last - 1.day

      # Finally, return the selected dates
      calculated_bed_nights[index ..]
    end

    private def literally_homeless_at_entry(bed_nights, first_date)
      enrollment_literally_homeless_at_entry(bed_nights.detect { |_, _, date| date == first_date }.first)
    end

    private def enrollment_literally_homeless_at_entry(enrollment)
      return true if enrollment.project_type.in?([0, 1, 4, 8])

      # See Identifying Clients Experiencing Literal Homelessness at Project Entry
      enrollment.project_type.in?([2, 3, 9, 10, 13]) &&
        (enrollment.prior_living_situation.in?(100..199) ||
          (enrollment.previous_street_essh? && enrollment.prior_living_situation.in?(200..299) && enrollment.los_under_threshold?) ||
            (enrollment.previous_street_essh? && enrollment.prior_living_situation.in?(300..499) && enrollment.los_under_threshold?))
    end

    private def include_ph_enrollment?(enrollment)
      # See Identifying Clients Experiencing Literal Homelessness at Project Entry
      return false unless enrollment.project_type.in?([2, 3, 9, 10, 13])

      enrollment.entry_date.between?(report_start_date, report_end_date) ||
        (enrollment.move_in_date.present? && enrollment.move_in_date.between?(report_start_date, report_end_date)) ||
        (enrollment.move_in_date.blank? && enrollment.exit_date.present? && enrollment.exit_date.between?(report_start_date, report_end_date))
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
