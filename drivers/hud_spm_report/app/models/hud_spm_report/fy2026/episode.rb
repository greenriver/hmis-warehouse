###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

### Summary of the Workflow
# *   **`candidate_bed_nights`**: Gathers all "potential" homeless nights across all relevant projects, even historical ones.
# *   **`excluded_bed_nights`**: Gathers all "housed" nights (TH stays or PH after move-in).
# *   **`compute_episode`**: Subtracts the housed nights from the potential homeless nights.
# *   **`filter_episode`**: Anchors the timeline to a night in the report range and walks backward until it hits a gap.

module HudSpmReport::Fy2026
  class Episode < HudReports::ReportClientBase
    CandidateBedNight = Data.define(:enrollment, :service_id, :date) do
      def <=>(other)
        return nil unless other.is_a?(self.class)

        # Primary sort by date
        res = date <=> other.date
        return res unless res.zero?

        # Tie-break by enrollment ID to ensure deterministic behavior.
        # We use a reverse tie-break (other <=> self) so that the "latest"
        # enrollment (highest ID) comes first
        res = other.enrollment.id <=> enrollment.id
        return res unless res.zero?

        # Further tie-break by service_id for NbN deterministic behavior
        (other.service_id || 0) <=> (service_id || 0)
      end
    end

    self.table_name = 'hud_report_spm_episodes'
    include Detail

    belongs_to :client, class_name: 'GrdaWarehouse::Hud::Client'

    has_many :enrollment_links
    has_many :enrollments, through: :enrollment_links
    has_many :bed_nights

    has_many :hud_reports_universe_members, inverse_of: :universe_membership, class_name: 'HudReports::UniverseMember', foreign_key: :universe_membership_id

    attr_accessor :report # FIXME?
    attr_writer :filter, :services

    def self.apply_search_scope(scope)
      scope.joins(:enrollments)
    end

    def self.search_columns
      HudSpmReport::Fy2026::SpmEnrollment.search_columns
    end

    def self.pluck_project_ids
      project_table = GrdaWarehouse::Hud::Project.arel_table
      joins(enrollments: { enrollment: :project }).distinct.pluck(project_table[:id])
    end

    def project_id
      enrollment.project_id
    end

    def data_source_id
      enrollment.data_source_id
    end

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
    def compute_episode(enrollments, included_project_types:, excluded_project_types:, include_self_reported_and_ph:, debug: false)
      all_allowed_types = (included_project_types + excluded_project_types).to_set
      enrollments = enrollments.filter { |e| e.project_type.in?(all_allowed_types) }
      return if enrollments.empty?

      raise 'Client undefined' unless client.present?

      @debugger = Debugger.new if debug
      @debugger&.log("\nClient: #{client.id}")
      @debugger&.log("  included_project_types: #{included_project_types.join(', ')}")
      @debugger&.log("  excluded_project_types: #{excluded_project_types.join(', ')}")
      @debugger&.log("  include_self_reported_and_ph: #{include_self_reported_and_ph}")
      @debugger&.log("  report_start_date: #{report_start_date.to_fs(:db)}")
      @debugger&.log("  report_end_date: #{report_end_date.to_fs(:db)}")

      # Step 1: Determine Client Eligibility
      # Step 2: Filter Non-Homeless Nights
      calculated_bed_nights = candidate_bed_nights(enrollments, included_project_types, include_self_reported_and_ph)
      @debugger&.log_timeline('calculated_bed_nights', calculated_bed_nights)
      excluded_dates = excluded_bed_nights(enrollments, excluded_project_types)
      @debugger&.log_timeline('excluded_dates', excluded_dates)
      allowed_bed_nights = calculated_bed_nights.reject { |bn| bn.date.in?(excluded_dates) }
      @debugger&.log_timeline('allowed_bed_nights', allowed_bed_nights)

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

      # To be included, in both 1a and 1b you need a homeless enrollment overlapping the range
      # Step 1d: Preserve every relevant bed night which caused the client to be considered active in the date range.
      # (Note: Step 1d-iii for PH says dates between start and move-in, which are already in allowed_bed_nights)
      inclusion_dates = allowed_bed_nights
      @debugger&.log_timeline('inclusion_dates', inclusion_dates)
      return unless inclusion_dates.present?

      # Steps 3-6: Determine episode range and include contiguous nights
      # Collect all possible nights including self-reported (Step 5)
      all_candidate_nights = allowed_bed_nights
      if include_self_reported_and_ph
        # Step 5: For each relevant project stay, add self-reported dates if meeting literal homelessness criteria
        pre_entry_dates = add_self_reported([], enrollments).reject { |bn| bn.date.in?(excluded_dates) }
        @debugger&.log_timeline('pre_entry_dates', pre_entry_dates)
        all_candidate_nights += pre_entry_dates
      end

      filtered_bed_nights = filter_episode(all_candidate_nights)
      @debugger&.log_timeline('filtered_bed_nights', filtered_bed_nights)

      return unless filtered_bed_nights.present?

      enrollment_links_array = []
      any_bed_nights_in_report_range = filtered_bed_nights.any? { |bn| bn.date.between?(report_start_date, report_end_date) }

      enrollment_ids = filtered_bed_nights.map { |bn| bn.enrollment.id }.uniq
      enrollment_ids.each do |enrollment_id|
        enrollment_links_array << EnrollmentLink.new(
          enrollment_id: enrollment_id,
        )
      end

      first_date, last_date, days_homeless, first_date_enrollments = compute_episode_statistics(filtered_bed_nights)
      literally_homeless_at_entry = first_date_enrollments.any? do |enrollment|
        enrollment_literally_homeless_at_entry(enrollment)
      end

      assign_attributes(
        first_date: first_date,
        last_date: last_date,
        days_homeless: days_homeless,
        literally_homeless_at_entry: literally_homeless_at_entry,
      )

      {
        episode: self,
        bed_nights: [],
        enrollment_links: enrollment_links_array,
        any_bed_nights_in_report_range: any_bed_nights_in_report_range,
      }
    end

    # @param bed_nights [Array<CandidateBedNight>]
    private def compute_episode_statistics(bed_nights)
      min_val = bed_nights[0].date
      max_val = bed_nights[0].date
      distinct = {}
      distinct_count = 0
      first_date_enrollments = Set.new

      bed_nights.each do |bn|
        date = bn.date
        enrollment = bn.enrollment

        if date < min_val
          min_val = date
          first_date_enrollments = Set.new([enrollment]) # Reset to just this enrollment
        elsif date == min_val
          first_date_enrollments.add(enrollment) # Add to enrollments for first date
        end
        max_val = date if date > max_val

        next if distinct.key?(date)

        distinct[date] = true
        distinct_count += 1
      end

      # Return min date, max date, count of distinct dates, and enrollments for min date
      [min_val, max_val, distinct_count, first_date_enrollments]
    end

    private def candidate_bed_nights(enrollments, project_types, include_self_reported_and_ph)
      bed_nights = {} # Hash with date as key so we only get one candidate per overlapping night
      enrollments = enrollments.select do |e|
        # For PH projects, only stays meeting the Identifying Clients Experiencing Literal Homelessness at Project Entry criteria are included in time experiencing homelessness.
        in_project_type = e.project_type.in?(project_types)
        # Always drop PH that wasn't literally homeless at entry or not in report range
        # NOTE: PH is never in the project types, but included because of include_self_reported_and_ph
        if include_self_reported_and_ph && e.project_type.in?(HudHelper.util('2026').project_type_number_from_code(:ph))
          enrollment_literally_homeless_at_entry(e) && include_ph_enrollment?(e)
        else
          in_project_type
        end
      end
      enrollments.each do |enrollment|
        if enrollment.project_type.in?(HudHelper.util('2026').project_type_number_from_code(:es_nbn))
          next unless enrollment.enrollment.present? # Skip if the enrollment has disappeared (e.g., a concurrent import deleted it)

          # https://files.hudexchange.info/resources/documents/System-Performance-Measures-HMIS-Programming-Specifications-September-2023.pdf - p11
          # For ES-NbN, "bed night" means the separate bed night records dated between the client's [project start date] and the
          # lesser of the ([project exit date] – 1) or [report end date]. Bed night records dated on the client's exit date
          # represent an error in data entry.
          first_night = enrollment.entry_date
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

                # return a CandidateBedNight, using the index in place of the id so we don't need to load
                # it from the DB (middle item needs to be unique within the enrollment)
                CandidateBedNight.new(enrollment: enrollment, service_id: i, date: date)
              end.compact.group_by(&:date).
              transform_values { |v| Array.wrap(v).last }, # Unique by date
          )
        else
          start_date = enrollment.entry_date
          end_date = if enrollment.project_type.in?(HudHelper.util('2026').project_type_number_from_code(:ph))
            # PH only gets days before move-in, if there is one
            enrollment.move_in_date || enrollment.exit_date
          else
            enrollment.exit_date
          end
          # The exit day is not a bed-night
          end_date -= 1.day if end_date.present?
          # Don't include days after the end of the reporting period
          end_date = [end_date, report_end_date].compact.min
          (start_date .. end_date).each do |date|
            bed_nights[date] = CandidateBedNight.new(enrollment: enrollment, service_id: nil, date: date)
          end
        end
      end

      bed_nights.values
    end

    private def excluded_bed_nights(enrollments, project_types)
      bed_nights = Set.new
      enrollments = enrollments.select { |e| e.project_type.in?(project_types) }
      enrollments.each do |enrollment|
        if enrollment.project_type.in?(HudHelper.util('2026').project_type_number_from_code(:th))
          # TH bed nights are not considered homeless
          # The exit day, if present, is not a a bed night
          end_date = if enrollment.exit_date
            [enrollment.exit_date - 1.day, report_end_date].min
          else
            report_end_date
          end
          (enrollment.entry_date .. end_date).each { |date| bed_nights.add(date) }
        elsif enrollment.project_type.in?(HudHelper.util('2026').project_type_number_from_code(:ph))
          # PH bed nights on or after move in are not considered homeless
          next unless enrollment.move_in_date.present?

          # The exit day, if present, is not a a bed night
          end_date = if enrollment.exit_date
            [enrollment.exit_date - 1.day, report_end_date].min
          else
            report_end_date
          end
          (enrollment.move_in_date .. end_date).each { |date| bed_nights.add(date) }
        else
          raise 'Unexpected project type, no exclusion rules'
        end
      end

      bed_nights
    end

    private def add_self_reported(existing_bed_nights, enrollments)
      bed_nights = existing_bed_nights.index_by(&:date)
      enrollments.each do |enrollment|
        next unless enrollment_literally_homeless_at_entry(enrollment)

        if enrollment.project_type.in?(HudHelper.util('2026').project_type_number_from_code(:es_nbn))
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
          # b.	For night-by-night based shelter stays, determine the client's [earliest bed night] dated >= [project start date] and <= [project exit date].  If [earliest bed night] >= [lookback stop date], then every night from [approximate date this episode of homelessness started] up to and including [earliest bed night] should also be considered nights experiencing homelessness. For example, a response of "9/16/2022" with the client's earliest bed night of 11/15/2022 would effectively include bed nights for 9/16/2022, 9/17/2022, 9/18/2022… up to and including 11/15/2022.  Naturally this does not mean the client was physically present at this specific shelter on these nights, but these dates are nonetheless included in the client's total time experiencing homelessness.
          next unless earliest_bed_night >= lookback_date && start_date < enrollment.entry_date

          (start_date .. earliest_bed_night).each do |date|
            bed_nights[date] ||= CandidateBedNight.new(enrollment: enrollment, service_id: nil, date: date) # Add the day if not already present
          end
        else
          # Self-reported dates earlier than the entry date if present and the **project** start is on or after the lookback date
          start_date = [enrollment.start_of_homelessness, enrollment.entry_date].compact.min
          # a.	For entry-exit based project stays, if the [project start date] is >= [lookback stop date], then every night from [approximate date this episode of homelessness started] up to and including [project start date] should also be considered nights experiencing homelessness, even if response in [approximate date this episode of homelessness started] extends prior to [lookback stop date].  For example, a response in [approximate date this episode of homelessness started] of "2/14/2022" with a [project start date] of 5/15/2022 would cause every night from 2/14/2022 through and including 5/15/2022 to be included in the client's dataset of nights experiencing homelessness.
          next unless enrollment.entry_date >= lookback_date && start_date < enrollment.entry_date

          (start_date .. enrollment.entry_date).each do |date|
            bed_nights[date] ||= CandidateBedNight.new(enrollment: enrollment, service_id: nil, date: date) # Add the day if not already present
          end
        end
      end

      bed_nights.values
    end

    # 3.	Utilizing data selected in step 1 and modified in step 2, determine each client's latest homeless bed night which is >= [report start date] and <= [report end date].  This date becomes that particular client's [client end date].
    #   a.	This date should be no later than the end date of the report ([client end date] must be <= [report end date]), in the event a project stay extends past the [report end date].
    #   b.	For enrollments in entry exit emergency shelters, this date should be one day prior to the client's exit date, or the [report end date], whichever is earlier.  It cannot be the client's exit date since that date does not represent a bed night.
    #   c.	For enrollments in night-by-night emergency shelters, this date must be based on recorded bed nights and not on the client's start or exit date.
    #   d.	Measure 1b: Be sure not to include the [housing move-in date] itself, as this date does not represent a night experiencing homelessness.
    # 4.	For each active client, create a [client start date] which is 365 days prior to the [client end date] going back no further than the [lookback stop date].
    #   a.	[Client start date] = [client end date] – 365 days.
    #   b.	A [client start date] will usually be prior to the [report start date].
    #
    # @param bed_nights [Array<CandidateBedNight>] Array of candidate bed nights to be processed
    # @return [Array<CandidateBedNight>, nil] Filtered bed nights for the episode, or nil if none qualify
    private def filter_episode(bed_nights)
      return if bed_nights.blank?

      # Sort by date to ensure chronological order, dedupe by date
      bed_nights = bed_nights.sort.uniq(&:date)

      # Keep bed nights that are:
      # - on or after the client's date of birth
      # - AND (on or after the lookback date
      #   OR associated with an enrollment that started on or after the lookback date)
      #
      # Per spec (Step 5): "include additional nights experiencing homelessness based on
      # [approximate date this episode of homelessness started] up to and including
      # [project start date]... even if response extends prior to [lookback stop date]"
      client_dob = client&.dob
      bed_nights = bed_nights.select do |bn|
        next false if client_dob && bn.date < client_dob

        bn.date >= lookback_date || bn.enrollment.entry_date >= lookback_date
      end

      # If we've filtered out all bed nights, return nil
      return if bed_nights.empty?

      # Step 3: Determine client's end date (latest homeless bed night in report range)
      # Must be >= report_start_date and <= report_end_date.
      # bed_nights are already capped at report_end_date.
      client_end_date = bed_nights.reverse_each.find { |bn| bn.date >= report_start_date }&.date
      return if client_end_date.nil?

      # Step 4: Client start date is 365 days prior to end date
      # going back no further than the [lookback stop date] or client DOB.
      client_start_date = [client_end_date - 365.days, lookback_date, client_dob].compact.max

      @debugger&.log("client_start_date: #{client_start_date.to_fs(:db)}")
      @debugger&.log("client_end_date: #{client_end_date.to_fs(:db)}")

      # Step 6a (Forward): Find first index where date >= client_start_date
      # All nights from here to end are included (gaps allowed in forward direction)
      forward_start_index = bed_nights.bsearch_index { |bn| bn.date >= client_start_date } || bed_nights.length

      # Step 6b (Backward): Include contiguous dates before client_start_date
      # Walk backwards until there is a gap > 1 day or we hit lookback_date
      backward_start_index = forward_start_index

      if forward_start_index.positive?
        # "To be contiguous, a date must be no more than one day earlier than
        # another date already in the client's dataset or the [client start date]"
        contiguity_edge = client_start_date

        (forward_start_index - 1).downto(0) do |i|
          bn = bed_nights[i]
          night_date = bn.date

          break if night_date < lookback_date && bn.enrollment.entry_date < lookback_date

          break unless (contiguity_edge - night_date).to_i <= 1

          # Contiguous - include this night and continue walking back
          backward_start_index = i
          contiguity_edge = night_date

          # Gap > 1 day found - "the period of at least one day when a client
          # is not experiencing homelessness" - stop here
        end
      end

      # Return the selected bed nights (contiguous backward + all forward)
      bed_nights[backward_start_index..]
    end

    private def enrollment_literally_homeless_at_entry(enrollment)
      return true if enrollment.project_type.in?([0, 1, 4, 8])

      # See Identifying Clients Experiencing Literal Homelessness at Project Entry
      enrollment.project_type.in?([2, 3, 9, 10, 13]) &&
        (enrollment.prior_living_situation.in?(100..199) ||
          (enrollment.previous_street_essh? && enrollment.prior_living_situation.in?(200..299) && enrollment.los_under_threshold?) ||
          (enrollment.previous_street_essh? && (enrollment.prior_living_situation.in?(0..99) || enrollment.prior_living_situation.in?(300..499)) && enrollment.los_under_threshold?))
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
