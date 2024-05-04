###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# NOTE: This should be updated and added to for any functionality or additional attributes and only overridden where the defaults are different or where the options are incompatible with this base class.
module Filters
  class FilterBase < ::ModelForm
    include AvailableSubPopulations
    include ArelHelper
    include ApplicationHelper
    include Filter::FilterScopes
    include ActionView::Helpers::TagHelper
    include ActionView::Context

    attribute :on, Date, lazy: true, default: ->(r, _) { r.default_on }
    attribute :start, Date, lazy: true, default: ->(r, _) { r.default_start }
    attribute :end, Date, lazy: true, default: ->(r, _) { r.default_end }
    attribute :enforce_one_year_range, Boolean, default: true
    attribute :require_service_during_range, Boolean, default: ->(_, _) { GrdaWarehouse::Config.get(:require_service_for_reporting_default) }
    attribute :sort
    attribute :heads_of_household, Boolean, default: false
    attribute :comparison_pattern, Symbol, default: ->(r, _) { r.default_comparison_pattern }
    attribute :household_type, Symbol, default: :all
    attribute :hoh_only, Boolean, default: false
    attribute :default_project_type_codes, Array, default: HudUtility2024.homeless_project_type_codes
    attribute :project_type_codes, Array, lazy: true, default: ->(r, _) { r.default_project_type_codes }
    attribute :project_type_numbers, Array, default: ->(_r, _) { [] }
    attribute :veteran_statuses, Array, default: []
    attribute :age_ranges, Array, default: []
    attribute :genders, Array, default: []
    attribute :races, Array, default: []
    attribute :length_of_times, Array, default: []
    attribute :destination_ids, Array, default: []
    attribute :prior_living_situation_ids, Array, default: []
    attribute :default_on, Date, default: Date.current
    attribute :default_start, Date, default: (Date.current - 1.year).beginning_of_year
    attribute :default_end, Date, default: (Date.current - 1.year).end_of_year

    attribute :user_id, Integer, default: nil
    attribute :project_ids, Array, default: []
    attribute :project_group_ids, Array, default: []
    attribute :organization_ids, Array, default: []
    attribute :data_source_ids, Array, default: []
    attribute :funder_ids, Array, default: []
    attribute :cohort_ids, Array, default: []
    attribute :secondary_cohort_ids, Array, default: []
    attribute :cohort_column, String, default: nil
    attribute :cohort_column_housed_date, String, default: nil
    attribute :cohort_column_matched_date, String, default: nil
    attribute :cohort_column_voucher_type, String, default: nil
    attribute :coc_codes, Array, default: []
    attribute :coc_code, String, default: ->(_, _) { GrdaWarehouse::Config.get(:site_coc_codes) }
    attribute :sub_population, Symbol, default: :clients
    attribute :start_age, Integer, default: 17
    attribute :end_age, Integer, default: 25
    attribute :ph, Boolean, default: false
    attribute :disabilities, Array, default: []
    attribute :indefinite_disabilities, Array, default: []
    attribute :dv_status, Array, default: []
    attribute :currently_fleeing, Array, default: []
    attribute :chronic_status, Boolean, default: nil
    attribute :coordinated_assessment_living_situation_homeless, Boolean, default: false
    attribute :ce_cls_as_homeless, Boolean, default: false
    attribute :limit_to_vispdat, Symbol, default: :all_clients
    attribute :times_homeless_in_last_three_years, Array, default: []
    attribute :rrh_move_in, Boolean, default: false
    attribute :psh_move_in, Boolean, default: false
    attribute :first_time_homeless, Boolean, default: false
    attribute :returned_to_homelessness_from_permanent_destination, Boolean, default: false
    attribute :creator_id, Integer, default: nil
    attribute :report_version, Symbol
    attribute :inactivity_days, Integer, default: 365 * 2
    attribute :lsa_scope, Integer, default: nil
    attribute :involves_ce, String, default: nil
    attribute :disabling_condition, Boolean, default: nil
    attribute :dates_to_compare, Symbol, default: :entry_to_exit
    attribute :required_files, Array, default: []
    attribute :optional_files, Array, default: []
    attribute :active_roi, Boolean, default: false
    attribute :mask_small_populations, Boolean, default: false
    attribute :secondary_project_ids, Array, default: []
    attribute :secondary_project_group_ids, Array, default: []

    # NOTE: this is needed to support old reports with existing options hashes containing ethnicities
    # we won't actually do anything with it
    attribute :ethnicities, Array, default: []

    validates_presence_of :start, :end

    # Incorporate anything that might change the results
    def cache_key
      to_h
    end

    # use incoming data, if not available, use previously set value, or default value
    def update(filters) # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity, Metrics/AbcSize
      return self unless filters.present?

      filters = filters.to_h.with_indifferent_access

      self.on = filters.dig(:on)&.to_date || on
      self.start = filters.dig(:start)&.to_date || start
      self.end = filters.dig(:end)&.to_date || self.end
      # Allow multi-year filters if we explicitly passed in something that isn't truthy
      enforce_range = filters.dig(:enforce_one_year_range)
      self.enforce_one_year_range = enforce_range.in?(['1', 'true', true]) unless enforce_range.nil?
      require_service = filters.dig(:require_service_during_range)
      self.require_service_during_range = require_service.in?(['1', 'true', true]) unless require_service.nil?
      self.comparison_pattern = clean_comparison_pattern(filters.dig(:comparison_pattern)&.to_sym)
      # NOTE: If an installation is Multi-CoC and a user has assigned CoC Codes,
      # there can be odd behavior if the coc_codes key doesn't exist in the filter params
      self.coc_codes = filters.dig(:coc_codes)&.select { |code| available_coc_codes&.include?(code) }.presence || coc_codes.presence
      self.coc_codes = user.coc_codes.presence || coc_codes.presence if GrdaWarehouse::Config.get(:multi_coc_installation) && ! filters.key?(:coc_codes)
      self.coc_code = filters.dig(:coc_code) if available_coc_codes&.include?(filters.dig(:coc_code))
      self.household_type = filters.dig(:household_type)&.to_sym || household_type
      unless filters.dig(:hoh_only).nil?
        filter_hoh = filters.dig(:hoh_only).in?(['1', 'true', true])
        self.heads_of_household = filter_hoh
        self.hoh_only = filter_hoh
      end
      self.default_project_type_codes = Array.wrap(filters.dig(:default_project_type_codes))&.reject(&:blank?) if filters.key?(:default_project_type_codes)
      if filters.key?(:project_type_codes)
        self.project_type_codes = Array.wrap(filters.dig(:project_type_codes))&.reject(&:blank?)
      elsif filters.key?(:project_type_numbers)
        self.project_type_codes = []
      else
        self.project_type_codes = project_type_codes
      end
      self.project_type_numbers = filters.dig(:project_type_numbers)&.reject(&:blank?)&.map(&:to_i).presence || project_type_numbers
      self.data_source_ids = filters.dig(:data_source_ids)&.reject(&:blank?)&.map(&:to_i).presence || data_source_ids
      self.organization_ids = filters.dig(:organization_ids)&.reject(&:blank?)&.map(&:to_i).presence || organization_ids
      self.project_ids = filters.dig(:project_ids)&.reject(&:blank?)&.map(&:to_i).presence || project_ids
      self.funder_ids = filters.dig(:funder_ids)&.reject(&:blank?)&.map(&:to_i).presence || funder_ids
      self.veteran_statuses = filters.dig(:veteran_statuses)&.reject(&:blank?)&.map(&:to_i).presence || veteran_statuses
      self.age_ranges = filters.dig(:age_ranges)&.reject(&:blank?)&.map(&:to_sym).presence || age_ranges
      self.genders = filters.dig(:genders)&.reject(&:blank?)&.map(&:to_i).presence || genders
      self.sub_population = filters.dig(:sub_population)&.to_sym || sub_population
      self.races = filters.dig(:races)&.select { |race| HudUtility2024.races(multi_racial: true).keys.include?(race) }.presence || races
      self.project_group_ids = filters.dig(:project_group_ids)&.reject(&:blank?)&.map(&:to_i).presence || project_group_ids
      self.prior_living_situation_ids = filters.dig(:prior_living_situation_ids)&.reject(&:blank?)&.map(&:to_i).presence || prior_living_situation_ids
      self.destination_ids = filters.dig(:destination_ids)&.reject(&:blank?)&.map(&:to_i).presence || destination_ids
      self.length_of_times = filters.dig(:length_of_times)&.reject(&:blank?)&.map(&:to_sym).presence || length_of_times
      self.cohort_ids = filters.dig(:cohort_ids)&.reject(&:blank?)&.map(&:to_i).presence || cohort_ids
      self.secondary_cohort_ids = filters.dig(:secondary_cohort_ids)&.reject(&:blank?)&.map(&:to_i).presence || secondary_cohort_ids
      self.cohort_column = filters.dig(:cohort_column)&.presence || cohort_column
      self.cohort_column_voucher_type = filters.dig(:cohort_column_voucher_type)&.presence || cohort_column_voucher_type
      self.cohort_column_housed_date = filters.dig(:cohort_column_housed_date)&.presence || cohort_column_housed_date
      self.cohort_column_matched_date = filters.dig(:cohort_column_matched_date)&.presence || cohort_column_matched_date

      self.disabilities = filters.dig(:disabilities)&.reject(&:blank?)&.map(&:to_i).presence || disabilities
      self.indefinite_disabilities = filters.dig(:indefinite_disabilities)&.reject(&:blank?)&.map(&:to_i).presence || indefinite_disabilities
      self.dv_status = filters.dig(:dv_status)&.reject(&:blank?)&.map(&:to_i).presence || dv_status
      self.currently_fleeing = filters.dig(:currently_fleeing)&.reject(&:blank?)&.map(&:to_i).presence || currently_fleeing
      self.chronic_status = filters.dig(:chronic_status).in?(['1', 'true', true]) unless filters.dig(:chronic_status).nil? || filters.dig(:chronic_status) == ''
      self.rrh_move_in = filters.dig(:rrh_move_in).in?(['1', 'true', true]) unless filters.dig(:rrh_move_in).nil?
      self.psh_move_in = filters.dig(:psh_move_in).in?(['1', 'true', true]) unless filters.dig(:psh_move_in).nil?
      self.first_time_homeless = filters.dig(:first_time_homeless).in?(['1', 'true', true]) unless filters.dig(:first_time_homeless).nil?
      self.involves_ce = filters.dig(:involves_ce).presence || involves_ce
      self.disabling_condition = filters.dig(:disabling_condition).in?(['1', 'true', true]) unless filters.dig(:disabling_condition).nil? || filters.dig(:disabling_condition) == ''
      self.returned_to_homelessness_from_permanent_destination = filters.dig(:returned_to_homelessness_from_permanent_destination).in?(['1', 'true', true]) unless filters.dig(:returned_to_homelessness_from_permanent_destination).nil?
      self.coordinated_assessment_living_situation_homeless = filters.dig(:coordinated_assessment_living_situation_homeless).in?(['1', 'true', true]) unless filters.dig(:coordinated_assessment_living_situation_homeless).nil?
      self.ce_cls_as_homeless = filters.dig(:ce_cls_as_homeless).in?(['1', 'true', true]) unless filters.dig(:ce_cls_as_homeless).nil?
      vispdat_limit = filters.dig(:limit_to_vispdat)&.to_sym
      self.limit_to_vispdat = vispdat_limit if vispdat_limit.present? && available_vispdat_limits.values.include?(vispdat_limit)
      self.ph = filters.dig(:ph).in?(['1', 'true', true]) unless filters.dig(:ph).nil?
      self.times_homeless_in_last_three_years = filters.dig(:times_homeless_in_last_three_years)&.reject(&:blank?)&.map(&:to_i) unless filters.dig(:times_homeless_in_last_three_years).nil?
      self.report_version = filters.dig(:report_version)&.to_sym
      self.creator_id = filters.dig(:creator_id).to_i unless filters.dig(:creator_id).nil?
      self.inactivity_days = filters.dig(:inactivity_days).to_i unless filters.dig(:inactivity_days).nil?
      self.lsa_scope = filters.dig(:lsa_scope).to_i unless filters.dig(:lsa_scope).blank?
      self.dates_to_compare = filters.dig(:dates_to_compare)&.to_sym || dates_to_compare
      self.mask_small_populations = filters.dig(:mask_small_populations).in?(['1', 'true', true]) unless filters.dig(:mask_small_populations).nil?
      self.required_files = filters.dig(:required_files)&.reject(&:blank?)&.map(&:to_i).presence || required_files
      self.optional_files = filters.dig(:optional_files)&.reject(&:blank?)&.map(&:to_i).presence || optional_files
      self.active_roi = filters.dig(:active_roi).in?(['1', 'true', true]) unless filters.dig(:active_roi).nil?
      self.secondary_project_ids = filters.dig(:secondary_project_ids)&.reject(&:blank?)&.map(&:to_i).presence || secondary_project_ids
      self.secondary_project_group_ids = filters.dig(:secondary_project_group_ids)&.reject(&:blank?)&.map(&:to_i).presence || secondary_project_group_ids

      ensure_dates_work if valid?
      self
    end
    alias set_from_params update

    def for_params
      {
        filters: {
          # NOTE: order specified here is used to echo selections in describe_filter
          on: on,
          start: start,
          end: self.end,
          comparison_pattern: comparison_pattern,
          coc_codes: coc_codes,
          coc_code: coc_code,
          household_type: household_type,
          project_type_codes: project_type_codes,
          project_type_numbers: project_type_numbers,
          data_source_ids: data_source_ids,
          organization_ids: organization_ids,
          project_ids: project_ids,
          funder_ids: funder_ids,
          veteran_statuses: veteran_statuses,
          age_ranges: age_ranges,
          genders: genders,
          sub_population: sub_population,
          races: races,
          project_group_ids: project_group_ids,
          cohort_ids: cohort_ids,
          secondary_cohort_ids: secondary_cohort_ids,
          cohort_column: cohort_column,
          cohort_column_voucher_type: cohort_column_voucher_type,
          cohort_column_housed_date: cohort_column_housed_date,
          cohort_column_matched_date: cohort_column_matched_date,
          hoh_only: hoh_only,
          prior_living_situation_ids: prior_living_situation_ids,
          destination_ids: destination_ids,
          length_of_times: length_of_times,
          disabilities: disabilities,
          indefinite_disabilities: indefinite_disabilities,
          dv_status: dv_status,
          currently_fleeing: currently_fleeing,
          chronic_status: chronic_status,
          rrh_move_in: rrh_move_in,
          psh_move_in: psh_move_in,
          first_time_homeless: first_time_homeless,
          involves_ce: involves_ce,
          disabling_condition: disabling_condition,
          returned_to_homelessness_from_permanent_destination: returned_to_homelessness_from_permanent_destination,
          coordinated_assessment_living_situation_homeless: coordinated_assessment_living_situation_homeless,
          ce_cls_as_homeless: ce_cls_as_homeless,
          limit_to_vispdat: limit_to_vispdat,
          enforce_one_year_range: enforce_one_year_range,
          require_service_during_range: require_service_during_range,
          times_homeless_in_last_three_years: times_homeless_in_last_three_years,
          report_version: report_version,
          ph: ph,
          creator_id: creator_id,
          inactivity_days: inactivity_days,
          lsa_scope: lsa_scope,
          required_files: required_files,
          optional_files: optional_files,
          active_roi: active_roi,
          mask_small_populations: mask_small_populations,
          secondary_project_ids: secondary_project_ids,
          secondary_project_group_ids: secondary_project_group_ids,
        },
      }
    end

    def to_h
      for_params[:filters]
    end
    alias inspect to_h

    def known_params
      [
        :on,
        :start,
        :end,
        :comparison_pattern,
        :household_type,
        :hoh_only,
        :sub_population,
        :chronic_status,
        :rrh_move_in,
        :psh_move_in,
        :first_time_homeless,
        :involves_ce,
        :disabling_condition,
        :returned_to_homelessness_from_permanent_destination,
        :coordinated_assessment_living_situation_homeless,
        :ce_cls_as_homeless,
        :coc_code,
        :limit_to_vispdat,
        :enforce_one_year_range,
        :require_service_during_range,
        :report_version,
        :ph,
        :creator_id,
        :inactivity_days,
        :lsa_scope,
        :cohort_column,
        :cohort_column_voucher_type,
        :cohort_column_housed_date,
        :cohort_column_matched_date,
        :dates_to_compare,
        :active_roi,
        :mask_small_populations,
        coc_codes: [],
        default_project_type_codes: [],
        project_types: [],
        project_type_codes: [],
        project_type_numbers: [],
        veteran_statuses: [],
        age_ranges: [],
        genders: [],
        races: [],
        data_source_ids: [],
        organization_ids: [],
        project_ids: [],
        funder_ids: [],
        project_group_ids: [],
        cohort_ids: [],
        secondary_cohort_ids: [],
        disability_summary_ids: [],
        destination_ids: [],
        disabilities: [],
        indefinite_disabilities: [],
        dv_status: [],
        currently_fleeing: [],
        prior_living_situation_ids: [],
        length_of_times: [],
        times_homeless_in_last_three_years: [],
        required_files: [],
        optional_files: [],
        secondary_project_ids: [],
        secondary_project_group_ids: [],
      ]
    end

    def all_known_keys
      known_params.map { |k| if k.is_a?(Hash) then k.keys else k end }.flatten
    end

    DEFAULT_LABELS = {
      on_date: 'On Date',
      on: 'On',
      date_range: 'Report Range',
      comparison_range: 'Comparison Range',
      comparison_pattern: 'Comparison Range',
      coc_codes: 'CoC Codes',
      coc_code: 'CoC Code',
      project_types: 'Project Types',
      sub_population: 'Sub-Population',
      data_sources: 'Data Sources',
      organizations: 'Organizations',
      projects: 'Projects',
      project_groups: 'Project Groups',
      funders: 'Funders',
      hoh_only: 'Heads of Household only?',
      coordinated_assessment_living_situation_homeless: 'Including CE homeless at entry',
      ce_cls_as_homeless: 'Including CE Current Living Situation Homeless',
      household_type: 'Household Type',
      age_ranges: 'Age Ranges',
      races: 'Races',
      genders: 'Genders',
      veteran_statuses: 'Veteran Statuses',
      length_of_time: 'Length of Time',
      prior_living_situations: 'Prior Living Situations',
      destinations: 'Destinations',
      disabilities: 'Disabilities',
      indefinite_disabilities: 'Indefinite and Impairing Disabilities',
      dv_status: 'DV Status',
      currently_fleeing: 'Currently Fleeing DV',
      chronic_status: 'Chronically at Entry',
      with_rrh_move_in: 'With RRH Move-in',
      with_psh_move_in: 'With PSH Move-in',
      first_time_homeless: 'First Time Homeless in Past Two Years',
      involves_ce: 'Participated in CE',
      disabling_condition: 'Disabling Condition',
      return_to_homelessness: 'Returned to Homelessness from Permanent Destination',
      client_limits: 'Client Limits',
      times_homeless_in_last_three_years: 'Times Homeless in Past 3 Years',
      require_service: 'Require Service During Range',
      dates_to_compare: 'Dates to Compare',
      required_files: 'Required Files',
      optional_files: 'Optional Files',
      active_roi: 'With Active ROI',
      require_service_during_range: 'Require Service During Range',
      mask_small_populations: 'Mask Small Populations',
      secondary_projects: 'Secondary Projects',
      secondary_project_groups: 'Secondary Project Groups',
    }.freeze

    private def label(key, labels)
      labels[key] || DEFAULT_LABELS[key]
    end

    def selected_params_for_display(single_date: false, labels: {}) # rubocop:disable Metrics/AbcSize
      {}.tap do |opts|
        if single_date
          opts[label(:on_date, labels)] = on
        else
          opts[label(:date_range, labels)] = date_range_words
        end
        opts[label(:comparison_range, labels)] = comparison_range_words if includes_comparison?
        opts[label(:coc_codes, labels)] = chosen_coc_codes if coc_codes.present?
        opts[label(:coc_code, labels)] = chosen_coc_code if coc_code.present?
        opts[label(:project_types, labels)] = chosen_project_types
        opts[label(:sub_population, labels)] = chosen_sub_population
        opts[label(:data_sources, labels)] = data_source_names if data_source_ids.any?
        opts[label(:organizations, labels)] = organization_names if organization_ids.any?
        opts[label(:projects, labels)] = project_names(project_ids) if project_ids.any?
        opts[label(:project_groups, labels)] = project_groups if project_group_ids.any?
        opts[label(:funders, labels)] = funder_names if funder_ids.any?
        opts[label(:hoh_only, labels)] = 'Yes' if hoh_only
        opts[label(:coordinated_assessment_living_situation_homeless, labels)] = 'Yes' if coordinated_assessment_living_situation_homeless
        opts[label(:ce_cls_as_homeless, labels)] = 'Yes' if ce_cls_as_homeless
        opts[label(:household_type, labels)] = chosen_household_type if household_type
        opts[label(:age_ranges, labels)] = chosen_age_ranges if age_ranges.any?
        opts[label(:races, labels)] = chosen_races if races.any?
        opts[label(:genders, labels)] = chosen_genders if genders.any?
        opts[label(:veteran_statuses, labels)] = chosen_veteran_statuses if veteran_statuses.any?
        opts[label(:length_of_time, labels)] = length_of_times if length_of_times.any?
        opts[label(:prior_living_situations, labels)] = chosen_prior_living_situations if prior_living_situation_ids.any?
        opts[label(:destinations, labels)] = chosen_destinations if destination_ids.any?
        opts[label(:disabilities, labels)] = chosen_disabilities if disabilities.any?
        opts[label(:indefinite_disabilities, labels)] = chosen_indefinite_disabilities if indefinite_disabilities.any?
        opts[label(:dv_status, labels)] = chosen_dv_status if dv_status.any?
        opts[label(:currently_fleeing, labels)] = chosen_currently_fleeing if currently_fleeing.any?
        opts[label(:chronic_status, labels)] = 'Yes' if chronic_status
        opts[label(:with_rrh_move_in, labels)] = 'Yes' if rrh_move_in
        opts[label(:with_psh_move_in, labels)] = 'Yes' if psh_move_in
        opts[label(:first_time_homeless, labels)] = 'Yes' if first_time_homeless
        opts[label(:involves_ce, labels)] = involves_ce if involves_ce.present?
        opts[label(:disabling_condition, labels)] = 'Yes' if disabling_condition
        opts[label(:return_to_homelessness, labels)] = 'Yes' if returned_to_homelessness_from_permanent_destination
        opts[label(:client_limits, labels)] = chosen_vispdat_limits if limit_to_vispdat != :all_clients
        opts[label(:times_homeless_in_last_three_years, labels)] = chosen_times_homeless_in_last_three_years if times_homeless_in_last_three_years.any?
        opts[label(:require_service, labels)] = 'Yes' if require_service_during_range
        opts[label(:required_files, labels)] = chosen_required_files if required_files.any?
        opts[label(:optional_files, labels)] = chosen_optional_files if required_files.any?
        opts[label(:active_roi, labels)] = 'Yes' if active_roi
        opts[label(:mask_small_populations, labels)] = 'Yes' if mask_small_populations
        opts[label(:secondary_projects, labels)] = project_names(secondary_project_ids) if secondary_project_ids.any?
        opts[label(:secondary_project_groups, labels)] = project_names(secondary_project_group_ids) if secondary_project_group_ids.any?
      end
    end

    def range
      start .. self.end
    end

    def as_date_range
      DateRange.new(start: start, end: self.end)
    end

    def comparison_range
      s, e = comparison_dates
      s .. e
    end

    def comparison_as_date_range
      s, e = comparison_dates
      DateRange.new(start: s, end: e)
    end

    def first
      range.begin
    end

    # fifteenth of relevant month
    def ides
      first + 14.days
    end

    def last
      range.end
    end

    def start_date
      first
    end

    def end_date
      last
    end

    # Date that can be used to find the closest PIT date, either that contained in the range,
    # or the most-recent PIT (last wednesday of January)
    # for simplicity, we'll just find the date in the january prior to the end date
    # 3/10/2020 - 6/20/2020 -> last wed in 1/2020
    # 10/1/2020 - 12/31/2020 -> last wed in 1/2020
    # 10/1/2020 - 9/30/2021 -> last wed in 1/2021
    # 10/1/2019 - 1/1/2020 -> last wed in 1/2019 (NOTE: end-date is before PIT date in 2020)
    def self.pit_date(date)
      wednesday = last_wednesday(date.year, 1)
      # date occurred on or after PIT date in this year
      return wednesday unless date.before?(wednesday)

      # date is early in January (before the last wednesday), use PIT date from prior year
      last_wednesday(date.year - 1, 1)
    end

    def self.last_wednesday(year, month)
      d = Date.new(year, month, 1)
      (d.beginning_of_month .. d.end_of_month).select(&:wednesday?).last
    end

    def pit_date
      self.class.pit_date(last)
    end

    def date_range_words
      "#{start_date.to_fs} - #{end_date.to_fs}"
    end

    def comparison_range_words
      s, e = comparison_dates
      "#{s.to_fs} - #{e.to_fs}"
    end

    def length
      (self.end - start).to_i
    rescue StandardError
      0
    end

    def effective_projects
      all_project_scope.where(id: effective_project_ids)
    end

    def effective_project_ids
      @effective_project_ids = effective_project_ids_from_projects
      @effective_project_ids += effective_project_ids_from_project_groups
      @effective_project_ids += effective_project_ids_from_organizations
      @effective_project_ids += effective_project_ids_from_data_sources
      @effective_project_ids += effective_project_ids_from_coc_codes

      # Add an invalid id if there are none
      @effective_project_ids = [0] if @effective_project_ids.empty?

      @effective_project_ids.uniq.reject(&:blank?)
    end

    def any_effective_project_ids?
      effective_project_ids.reject { |m| m&.zero? }.present?
    end

    def anded_effective_project_ids
      ids = []
      ids << effective_project_ids_from_projects
      ids << effective_project_ids_from_project_groups
      ids << effective_project_ids_from_organizations
      ids << effective_project_ids_from_data_sources
      ids << effective_project_ids_from_coc_codes
      ids << effective_project_ids_from_project_types
      ids.reject(&:empty?).reduce(&:&)
    end

    # Apply all known scopes
    # NOTE: by default we use coc_codes, if you need to filter by the coc_code singular, take note
    def apply(scope, report_scope_source, all_project_types: nil, multi_coc_code_filter: true, include_date_range: true, chronic_at_entry: true)
      @report_scope_source = report_scope_source
      @filter = self

      scope = apply_project_level_restrictions(scope, all_project_types: all_project_types, multi_coc_code_filter: multi_coc_code_filter, include_date_range: include_date_range)
      scope = apply_client_level_restrictions(scope, chronic_at_entry: chronic_at_entry)
      scope
    end

    def apply_client_level_restrictions(scope, chronic_at_entry: true)
      @filter = self
      scope = filter_for_household_type(scope)
      scope = filter_for_head_of_household(scope)
      scope = filter_for_age(scope)
      scope = filter_for_gender(scope)
      scope = filter_for_race(scope)
      scope = filter_for_veteran_status(scope)
      scope = filter_for_sub_population(scope)
      scope = filter_for_prior_living_situation(scope)
      scope = filter_for_destination(scope)
      scope = filter_for_disabilities(scope)
      scope = filter_for_indefinite_disabilities(scope)
      scope = filter_for_dv_status(scope)
      scope = filter_for_dv_currently_fleeing(scope)
      scope = if chronic_at_entry
        filter_for_chronic_at_entry(scope)
      else
        filter_for_chronic_status(scope)
      end
      scope = filter_for_rrh_move_in(scope)
      scope = filter_for_psh_move_in(scope)
      scope = filter_for_first_time_homeless_in_past_two_years(scope)
      scope = filter_for_returned_to_homelessness_from_permanent_destination(scope)
      scope = filter_for_ca_homeless(scope)
      scope = filter_for_ce_cls_homeless(scope)
      scope = filter_for_cohorts(scope)
      scope = filter_for_active_roi(scope)
      scope = filter_for_times_homeless(scope)
      scope
    end

    def apply_project_level_restrictions(scope, all_project_types: nil, multi_coc_code_filter: true, include_date_range: true)
      @filter = self
      scope = filter_for_user_access(scope)
      scope = filter_for_range(scope) if include_date_range
      scope = if multi_coc_code_filter
        filter_for_cocs(scope)
      else
        filter_for_coc(scope)
      end
      scope = filter_for_project_type(scope, all_project_types: all_project_types)
      scope = filter_for_projects(scope)
      scope = filter_for_funders(scope)
      scope = filter_for_data_sources(scope)
      scope = filter_for_organizations(scope)
      scope
    end

    def report_scope_source
      @report_scope_source ||= GrdaWarehouse::ServiceHistoryEnrollment.entry
    end

    def all_projects?
      effective_project_ids.sort == all_project_ids.sort
    end

    def project_ids
      @project_ids.reject(&:blank?)
    end

    def secondary_project_ids
      @secondary_project_ids.reject(&:blank?)
    end

    def coc_codes
      @coc_codes.reject(&:blank?)
    end

    def project_group_ids
      @project_group_ids.reject(&:blank?)
    end

    def secondary_project_group_ids
      @secondary_project_group_ids.reject(&:blank?)
    end

    def organization_ids
      @organization_ids.reject(&:blank?)
    end

    def data_source_ids
      @data_source_ids.reject(&:blank?)
    end

    def funder_ids
      @funder_ids.reject(&:blank?)
    end

    def cohort_ids
      @cohort_ids.reject(&:blank?)
    end

    def secondary_cohort_ids
      @secondary_cohort_ids.reject(&:blank?)
    end

    def effective_project_ids_from_projects
      @effective_project_ids_from_projects ||= project_ids.reject(&:blank?).map(&:to_i)
    end

    def effective_project_ids_from_project_groups
      pgs = project_group_ids.reject(&:blank?).map(&:to_i)
      return [] if pgs.empty? # if there are no project groups selected, there are no projects

      @effective_project_ids_from_project_groups ||= GrdaWarehouse::ProjectGroup.joins(:projects).
        merge(GrdaWarehouse::ProjectGroup.viewable_by(user)).
        where(id: pgs).
        pluck(p_t[:id].as('project_id'))
    end

    def effective_project_ids_from_secondary_project_groups
      pgs = secondary_project_group_ids.reject(&:blank?).map(&:to_i)
      return [] if pgs.empty? # if there are no project groups selected, there are no projects

      @effective_project_ids_from_secondary_project_groups ||= GrdaWarehouse::ProjectGroup.joins(:projects).
        merge(GrdaWarehouse::ProjectGroup.viewable_by(user)).
        where(id: pgs).
        pluck(p_t[:id].as('project_id'))
    end

    def effective_project_ids_from_organizations
      orgs = organization_ids.reject(&:blank?).map(&:to_i)
      return [] if orgs.empty?

      @effective_project_ids_from_organizations ||= all_organizations_scope.
        where(id: orgs).
        pluck(p_t[:id].as('project_id'))
    end

    def effective_project_ids_from_data_sources
      sources = data_source_ids.reject(&:blank?).map(&:to_i)
      return [] if sources.empty?

      @effective_project_ids_from_data_sources ||= all_data_sources_scope.
        where(id: sources).
        pluck(p_t[:id].as('project_id'))
    end

    def effective_project_ids_from_project_types
      return [] if project_type_ids.empty?

      @effective_project_ids_from_project_types ||= all_project_scope.
        with_project_type(project_type_ids).
        pluck(p_t[:id].as('project_id'))
    end

    # NOTE: singular CoC Code is only used to limit CoC Code, whereas CoC Codes is used to limit projects
    def effective_project_ids_from_coc_codes
      codes = coc_codes.reject(&:blank?)
      return [] if codes.empty?

      @effective_project_ids_from_coc_codes ||= all_coc_code_scope.in_coc(coc_code: codes).
        pluck(p_t[:id].as('project_id'))
    end

    def all_project_ids
      @all_project_ids ||= all_project_scope.pluck(:id)
    end

    def all_project_scope
      GrdaWarehouse::Hud::Project.viewable_by(user, permission: :can_view_assigned_reports)
    end

    def all_organizations_scope
      GrdaWarehouse::Hud::Organization.joins(:projects).
        merge(all_project_scope)
    end

    def all_data_sources_scope
      GrdaWarehouse::DataSource.joins(:projects).
        merge(all_project_scope)
    end

    def all_funders_scope
      GrdaWarehouse::Hud::Funder.joins(:project).
        merge(all_project_scope)
    end

    def all_coc_code_scope
      GrdaWarehouse::Hud::ProjectCoc.joins(:project).
        merge(all_project_scope)
    end

    def all_project_group_scope
      GrdaWarehouse::ProjectGroup.all
    end

    # Select display options
    def project_type_options_for_select(id_limit: [])
      options = HudUtility2024.project_types.invert
      options = options.select { |_, id| id.in?(id_limit) } if id_limit.present?
      options.map do |text, id|
        [
          "#{text} (#{id})",
          id,
        ]
      end
    end

    def project_type_code_options_for_select
      HudUtility2024.project_type_group_titles.select { |k, _| k.in?(default_project_type_codes) }.freeze.invert
    end

    def project_options_for_select(user:)
      all_project_scope.options_for_select(user: user)
    end

    def organization_options_for_select(user:)
      all_organizations_scope.distinct.options_for_select(user: user)
    end

    def data_source_options_for_select(user:)
      all_data_sources_scope.options_for_select(user: user)
    end

    def funder_options_for_select(user:)
      all_funders_scope.options_for_select(user: user)
    end

    def coc_code_options_for_select(user:)
      GrdaWarehouse::Lookups::CocCode.options_for_select(user: user)
    end

    def project_groups_options_for_select(user:)
      all_project_group_scope.options_for_select(user: user)
    end

    def cohorts_for_select(user:)
      GrdaWarehouse::Cohort.viewable_by(user).distinct.order(name: :asc).pluck(:name, :id)
    end

    # A list of select/drop-down type cohort columns where there is at least one choice.
    # This should give us a reasonable list of options to choose from
    def cohort_columns_for_select
      initialized_columns = GrdaWarehouse::CohortColumnOption.distinct.pluck(:cohort_column)
      GrdaWarehouse::Cohort.available_columns.select do |column|
        column.column.in?(initialized_columns) && ! column.title.match?(/^User Select \d+$/)
      end.map do |column|
        [
          column.title,
          column.column,
        ]
      end
    end

    def cohort_columns_for_dates
      GrdaWarehouse::Cohort.available_columns.select do |column|
        # Ignore non-dates and untranslated custom dates
        column.class.ancestors.include?(CohortColumns::CohortDate) && ! column.title.match?(/^User Date \d+$/)
      end.map do |column|
        [
          column.title,
          column.column,
        ]
      end
    end

    # End Select display options

    def clients_from_cohorts
      GrdaWarehouse::Hud::Client.joins(:cohort_clients).
        merge(GrdaWarehouse::CohortClient.active.where(cohort_id: cohort_ids)).
        distinct
    end

    def available_project_types
      HudUtility2024.project_type_group_titles.invert
    end

    def available_residential_project_types
      HudUtility2024.residential_type_titles.invert
    end

    def available_homeless_project_types
      HudUtility2024.homeless_type_titles.invert
    end

    def available_project_type_numbers
      ::HudUtility2024.project_types.invert
    end

    def available_vispdat_limits
      {
        'All clients' => :all_clients,
        'Only clients with VI-SPDATs' => :with_vispdat,
        'Only clients without VI-SPDATs' => :without_vispdat,
      }
    end

    def chosen_vispdat_limits
      available_vispdat_limits.invert[limit_to_vispdat]
    end

    def available_times_homeless_in_last_three_years
      ::HudUtility2024.times_homeless_options
    end

    def available_file_tags
      # acts_as_taggable_tags = ActsAsTaggableOn::Tag.all.index_by(&:name)
      GrdaWarehouse::AvailableFileTag.preload(:tag).grouped.
        map do |group, tags|
        [
          group,
          tags.map do |tag|
            next unless tag&.name.present? && tag&.tag.present?

            [tag.name, tag.tag.id]
          end.compact,
        ]
      end.to_h
    end

    def chosen_times_homeless_in_last_three_years
      available_times_homeless_in_last_three_years.invert[times_homeless_in_last_three_years]
    end

    def project_type_ids
      ids = HudUtility2024.performance_reporting.values_at(
        *project_type_codes.reject(&:blank?).map(&:to_sym),
      ).flatten

      ids += project_type_numbers if project_type_numbers.any?
      ids
    end

    def selected_project_type_names
      HudUtility2024.residential_type_titles.values_at(*project_type_codes.reject(&:blank?).map(&:to_sym))
    end

    def user
      @user ||= User.find(user_id)
    end

    def available_sub_populations
      AvailableSubPopulations.available_sub_populations
    end

    def ce_options
      {
        'Yes' => 'Yes',
        'No' => 'No',
        'With CE Assessment' => 'With CE Assessment',
      }
    end

    def self.available_age_ranges
      {
        zero_to_four: '0 - 4',
        five_to_ten: '5 - 10',
        eleven_to_fourteen: '11 - 14',
        fifteen_to_seventeen: '15 - 17',
        under_eighteen: '< 18',
        eighteen_to_twenty_four: '18 - 24',
        twenty_five_to_twenty_nine: '25 - 29',
        thirty_to_thirty_four: '30 - 34',
        thirty_five_to_thirty_nine: '35 - 39',
        forty_to_forty_four: '40 - 44',
        forty_five_to_forty_nine: '45 - 49',
        fifty_to_fifty_four: '50 - 54',
        fifty_five_to_fifty_nine: '55 - 59',
        sixty_to_sixty_one: '60 - 61',
        sixty_two_to_sixty_four: '62 - 64',
        over_sixty_four: '65+',
      }.invert.freeze
    end

    def self.available_census_age_ranges
      {
        zero_to_four: '0 - 4',
        five_to_nine: '5 - 9',
        ten_to_fourteen: '10 - 14',
        fifteen_to_seventeen: '15 - 17',
        eighteen_to_twenty_four: '18 - 24',
        twenty_five_to_thirty_four: '25 - 34',
        thirty_five_to_forty_four: '35 - 44',
        forty_five_to_fifty_four: '45 - 54',
        fifty_five_to_sixty_four: '55 - 64',
        sixty_five_to_seventy_four: '65 - 74',
        seventy_five_to_eighty_four: '75 - 84',
        eighty_five_plus: '85+',
      }.invert.freeze
    end

    def available_age_ranges
      self.class.available_age_ranges
    end

    def self.age_range(description)
      case description
      when :zero_to_four
        0..4
      when :five_to_nine
        5..9
      when :five_to_ten
        5..10
      when :ten_to_fourteen
        10..14
      when :eleven_to_fourteen
        11..14
      when :fifteen_to_seventeen
        15..17
      when :under_eighteen
        0..17
      when :eighteen_to_twenty_four
        18..24
      when :twenty_five_to_twenty_nine
        25..29
      when :twenty_five_to_thirty_four
        25..34
      when :thirty_to_thirty_four
        30..34
      when :thirty_five_to_thirty_nine
        35..39
      when :thirty_five_to_forty_four
        35..44
      when :thirty_to_thirty_nine
        30..39
      when :forty_to_forty_four
        40..44
      when :forty_five_to_forty_nine
        45..49
      when :forty_five_to_fifty_four
        45..54
      when :forty_to_forty_nine
        40..49
      when :fifty_to_fifty_four
        50..54
      when :fifty_five_to_fifty_nine
        55..59
      when :fifty_five_to_sixty_four
        55..64
      when :sixty_to_sixty_one
        60..61
      when :sixty_two_to_sixty_four
        62..64
      when :over_sixty_one
        62..110
      when :over_sixty_four
        65..110
      when :sixty_five_to_seventy_four
        65..74
      when :seventy_five_to_eighty_four
        75..84
      when :eighty_five_plus
        85..110
      end
    end

    def available_inactivity_days
      {
        30 => '30 days',
        45 => '45 days',
        60 => '60 days',
        90 => '90 days',
        365 => '1 year',
        365 * 2 => '2 years',
        365 * 3 => '3 years',
        365 * 20 => '20 years',
      }.invert.freeze
    end

    def comparison_patterns
      {
        no_comparison_period: 'None',
        prior_year: 'Same period, prior year',
        prior_period: 'Prior Period',
        prior_fiscal_year: 'Prior Federal Fiscal Year',
      }.invert.freeze
    end

    def clean_comparison_pattern(pattern)
      comparison_patterns.values.detect { |m| m == pattern&.to_sym } || comparison_pattern.presence || default_comparison_pattern
    end

    def available_coc_codes
      @available_coc_codes ||= begin
        return GrdaWarehouse::Hud::ProjectCoc.distinct.pluck(GrdaWarehouse::Hud::ProjectCoc.coc_code_coalesce) if user.system_user?

        GrdaWarehouse::Lookups::CocCode.viewable_by(user).distinct.pluck(:coc_code)
      end
    end

    # disallow selection > 1 year, and reverse dates
    def ensure_dates_work
      ensure_date_order
      ensure_date_span
    end

    def ensure_date_order
      return unless last < first

      new_first = last
      self.end = first
      self.start = new_first
    end

    def ensure_date_span
      return unless enforce_one_year_range

      span = GrdaWarehouse::Config.get(:filter_date_span_years) || 1
      return if last - first < span.years.in_days

      self.end = first + span.years - 1.days
    end

    def default_comparison_pattern
      :no_comparison_period
    end

    def includes_comparison?
      comparison_pattern != :no_comparison_period
    end

    def default_project_type_numbers
      HudUtility2024.project_types_with_inventory
    end

    def describe_filter_as_html(keys = nil, limited: true, inline: false, labels: {})
      describe_filter(keys, labels: labels).uniq.map do |(k, v)|
        wrapper_classes = ['report-parameters__parameter']
        label_text = k
        if inline
          wrapper_classes << 'd-flex'
          label_text += ':' if label_text.present?
        end
        content_tag(:div, class: wrapper_classes) do
          label = content_tag(:label, label_text, class: 'label label-default parameter-label')
          if v.is_a?(Array)
            if limited
              count = v.count
              v = v.first(5)
              v << "#{count - 5} more" if count > 5
            end
            v = v.to_sentence
          end
          value_classes = ['label', 'label-primary', 'parameter-value']
          value_classes << 'pl-0' if inline
          label.concat(content_tag(:label, v, class: value_classes))
        end
      end.join.html_safe
    end

    def describe_filter(keys = nil, labels: {})
      [].tap do |descriptions|
        # only show "on" if explicitly chosen
        display_keys = for_params[:filters]
        display_keys.delete(:on) unless keys&.include?(:on)
        display_keys.each_key do |key|
          next if keys.present? && ! keys.include?(key)

          descriptions << describe(key, labels: labels)
        end
      end.compact
    end

    def describe(key, value = chosen(key), labels: {})
      title = case key
      when :start
        label(:date_range, labels)
      when :end
        nil
      when :comparison_pattern
        label(key, labels) if includes_comparison?
      when :data_source_ids
        label(:data_sources, labels)
      when :organization_ids
        label(:organizations, labels)
      when :project_ids
        label(:projects, labels)
      when :project_group_ids
        label(:project_groups, labels)
      when :funder_ids
        label(:funders, labels)
      when :project_type_codes, :project_type_ids, :project_type_numbers
        label(:project_types, labels)
      when :heads_of_household, :hoh_only
        label(:hoh_only, labels)
      when :limit_to_vispdat
        value = nil if limit_to_vispdat == :all_clients
        label(:client_limits, labels)
      when :destination_ids
        label(:destinations, labels)
      when :prior_living_situation_ids
        label(:prior_living_situations, labels)
      when :secondary_project_ids
        label(:secondary_projects, labels)
      when :secondary_project_group_ids
        label(:secondary_project_groups, labels)
      when :lsa_scope
        'LSA Scope'
      when :cohort_ids
        'Cohorts'
      when :secondary_cohort_ids
        'Cohort Inclusion'
      when :cohort_column
        'Cohort Column for Initiative Cohorts'
      when :cohort_column_voucher_type
        'Cohort Column for Voucher Type'
      when :cohort_column_housed_date
        'Cohort Column for House Date'
      when :cohort_column_matched_date
        'Cohort Column for Matched Date'
      else
        label(key, labels)
      end

      return unless value.present?

      [title, value]
    end

    def chosen(key) # rubocop:disable Metrics/CyclomaticComplexity
      case key
      when :start
        date_range_words
      when :end
        nil
      when :on
        on
      when :comparison_pattern
        comparison_range_words if includes_comparison?
      when :project_type_codes, :project_type_ids, :project_type_numbers
        chosen_project_types
      when :sub_population
        chosen_sub_population
      when :age_ranges
        chosen_age_ranges
      when :races
        chosen_races
      when :genders
        chosen_genders
      when :coc_codes
        chosen_coc_codes
      when :coc_code
        chosen_coc_code
      when :organization_ids
        chosen_organizations
      when :project_ids
        chosen_projects
      when :data_source_ids
        chosen_data_sources
      when :project_group_ids
        chosen_project_groups
      when :funder_ids
        chosen_funding_sources
      when :veteran_statuses
        chosen_veteran_statuses
      when :household_type
        chosen_household_type
      when :prior_living_situation_ids
        chosen_prior_living_situations
      when :destination_ids
        chosen_destinations
      when :disabilities
        chosen_disabilities
      when :indefinite_disabilities
        chosen_indefinite_disabilities
      when :dv_status
        chosen_dv_status
      when :currently_fleeing
        chosen_currently_fleeing
      when :heads_of_household, :hoh_only
        'Yes' if heads_of_household || hoh_only
      when :require_service_during_range
        'Yes' if require_service_during_range
      when :ce_cls_as_homeless
        'Yes' if ce_cls_as_homeless
      when :coordinated_assessment_living_situation_homeless
        'Yes' if coordinated_assessment_living_situation_homeless
      when :limit_to_vispdat
        chosen_vispdat_limits
      when :times_homeless_in_last_three_years
        chosen_times_homeless_in_last_three_years
      when :lsa_scope
        chosen_lsa_scope
      when :cohort_ids
        cohorts
      when :secondary_cohort_ids
        secondary_cohorts
      when :cohort_column
        cohort_column
      when :cohort_column_voucher_type
        cohort_column_voucher_type
      when :cohort_column_housed_date
        cohort_column_housed_date
      when :cohort_column_matched_date
        cohort_column_matched_date
      when :chronic_status
        case chronic_status
        when true
          'Yes'
        when false
          'No'
        end
      when :involves_ce
        case involves_ce
        when 'Yes'
          'Yes'
        when 'No'
          'No'
        when 'With CE Assessment'
          'With CE Assessment'
        end
      when :required_files
        chosen_required_files
      when :optional_files
        chosen_optional_files
      when :secondary_project_ids
        chosen_secondary_projects
      when :secondary_project_group_ids
        chosen_secondary_project_groups
      else
        val = send(key)
        val.instance_of?(String) ? val.titleize : val
      end
    end

    def chosen_sub_population
      AvailableSubPopulations.available_sub_populations.invert[sub_population]
    end

    def chosen_age_ranges
      age_ranges.map do |range|
        available_age_ranges.invert[range]
      end.join(', ')
    end

    def chosen_races
      races.map do |race|
        HudUtility2024.race(race, multi_racial: true)
      end
    end

    def chosen_genders
      genders.map do |gender|
        HudUtility2024.gender(gender)
      end
    end

    def chosen_coc_codes
      coc_codes
    end

    def chosen_coc_code
      coc_code
    end

    def chosen_organizations
      return nil unless organization_ids.reject(&:blank?).present?

      GrdaWarehouse::Hud::Organization.where(id: organization_ids).pluck(:OrganizationName)
    end

    def chosen_projects
      return nil unless project_ids.reject(&:blank?).present?

      # OK to use non-confidentialized ProjectName because confidential projects
      # are only select-able if user has permission to view their names
      GrdaWarehouse::Hud::Project.where(id: project_ids).pluck(:ProjectName)
    end

    def chosen_secondary_projects
      return nil unless secondary_project_ids.reject(&:blank?).present?

      # OK to use non-confidentialized ProjectName because confidential projects
      # are only select-able if user has permission to view their names
      GrdaWarehouse::Hud::Project.where(id: secondary_project_ids).pluck(:ProjectName)
    end

    def chosen_data_sources
      return nil unless data_source_ids.reject(&:blank?).present?

      GrdaWarehouse::DataSource.where(id: data_source_ids).pluck(:short_name)
    end

    def chosen_project_groups
      return nil unless project_group_ids.reject(&:blank?).present?

      GrdaWarehouse::ProjectGroup.where(id: project_group_ids).pluck(:name)
    end

    def chosen_secondary_project_groups
      return nil unless secondary_project_group_ids.reject(&:blank?).present?

      GrdaWarehouse::ProjectGroup.where(id: secondary_project_group_ids).pluck(:name)
    end

    def chosen_funding_sources
      return nil unless funder_ids.reject(&:blank?).present?

      funder_ids.map { |code| "#{HudUtility2024.funding_source(code&.to_i)} (#{code})" }
    end

    def chosen_veteran_statuses
      veteran_statuses.map do |veteran_status|
        HudUtility2024.veteran_status(veteran_status)
      end
    end

    def chosen_project_types
      project_type_ids.map do |type|
        HudUtility2024.project_type(type)
      end.uniq
    end

    def chosen_project_types_only_homeless?
      project_type_ids.sort == HudUtility2024.homeless_project_types.sort
    end

    def chosen_household_type
      household_type_string(household_type&.to_sym)
    end

    def household_type_string(type)
      return unless type

      available_household_types.invert[type] || 'Unknown'
    end

    def chosen_prior_living_situations
      prior_living_situation_ids.map do |id|
        available_prior_living_situations.invert[id]
      end.join(', ')
    end

    def chosen_destinations
      destination_ids.map do |id|
        available_destinations.invert[id]
      end.join(', ')
    end

    def chosen_disabilities
      disabilities.map do |id|
        available_disabilities.invert[id]
      end.join(', ')
    end

    def chosen_indefinite_disabilities
      indefinite_disabilities.map do |id|
        available_indefinite_disabilities.invert[id]
      end.join(', ')
    end

    def chosen_dv_status
      dv_status.map do |id|
        available_dv_status.invert[id]
      end.join(', ')
    end

    def chosen_required_files
      required_files.flat_map do |id|
        available_file_tags.values.flatten(1).find { |f| f.last == id }&.first
      end.join(', ')
    end

    def chosen_optional_files
      optional_files.flat_map do |id|
        available_file_tags.values.flatten(1).find { |f| f.last == id }&.first
      end.join(', ')
    end

    def chosen_currently_fleeing
      currently_fleeing.map do |id|
        available_currently_fleeing.invert[id]
      end.join(', ')
    end

    def chosen_lsa_scope
      case lsa_scope&.to_i
      when 1
        'System-Wide'
      when 2
        'Project-Focused'
      else
        'Auto Select'
      end
    end

    def data_source_names
      data_source_options_for_select(user: user).
        select do |_, id|
          data_source_ids.include?(id)
        end&.map(&:first)
    end

    def organization_names
      organization_options_for_select(user: user).
        values.
        flatten(1).
        select do |_, id|
          organization_ids.include?(id)
        end&.map(&:first)
    end

    def project_names(ids = project_ids)
      project_options_for_select(user: user).
        values.
        flatten(1).
        select do |_, id|
          ids.include?(id)
        end&.map(&:first)
    end

    def project_groups
      project_groups_options_for_select(user: user).select { |_, id| project_group_ids.include?(id) }&.map(&:first)
    end

    def funder_names
      funder_options_for_select(user: user).select { |_, id| funder_ids.include?(id.to_i) }&.map(&:first)
    end

    def cohorts
      cohorts_for_select(user: user).select { |_, id| cohort_ids.include?(id.to_i) }&.map(&:first)
    end

    def secondary_cohorts
      cohorts_for_select(user: user).select { |_, id| secondary_cohort_ids.include?(id.to_i) }&.map(&:first)
    end

    def chosen_secondary_cohorts
      GrdaWarehouse::Cohort.viewable_by(user).where(id: secondary_cohort_ids).distinct.order(name: :asc)
    end

    def available_household_types
      {
        all: 'All household types',
        without_children: 'Adult only Households',
        with_children: 'Adult and Child Households',
        only_children: 'Child only Households',
      }.invert.freeze
    end

    def available_dates_to_compare
      {
        entry_to_exit: 'Entry to Exit',
        date_to_street_to_entry: 'Date Homelessness Started to Entry',
        date_to_street_to_exit: 'Date Homelessness Started to Exit',
      }
    end

    def available_prior_living_situations(grouped: false)
      if grouped
        {
          'Homeless' => HudUtility2024.homeless_situation_options(as: :prior).map do |id, title|
            [
              "#{title} (#{id})",
              id,
            ]
          end.to_h,
          'Institutional' => HudUtility2024.institutional_situation_options(as: :prior).map do |id, title|
            [
              "#{title} (#{id})",
              id,
            ]
          end.to_h,
          'Temporary' => HudUtility2024.temporary_housing_situation_options(as: :prior).map do |id, title|
            [
              "#{title} (#{id})",
              id,
            ]
          end.to_h,
          'Permanent' => HudUtility2024.permanent_housing_situation_options(as: :prior).map do |id, title|
            [
              "#{title} (#{id})",
              id,
            ]
          end.to_h,
          'Other' => HudUtility2024.other_situation_options(as: :prior).map do |id, title|
            [
              "#{title} (#{id})",
              id,
            ]
          end.to_h,
        }
      else
        HudUtility2024.living_situations.map do |id, title|
          [
            "#{title} (#{id})",
            id,
          ]
        end.to_h
      end
    end

    def available_destinations(grouped: false)
      return HudUtility2024.valid_destinations.invert unless grouped

      {
        'Homeless' => HudUtility2024.homeless_situation_options(as: :destination).map do |id, title|
          [
            "#{title} (#{id})",
            id,
          ]
        end.to_h,
        'Institutional' => HudUtility2024.institutional_situation_options(as: :destination).map do |id, title|
          [
            "#{title} (#{id})",
            id,
          ]
        end.to_h,
        'Temporary' => HudUtility2024.temporary_destination_options.map do |id, title|
          [
            "#{title} (#{id})",
            id,
          ]
        end.to_h,
        'Permanent' => HudUtility2024.permanent_destination_options.map do |id, title|
          [
            "#{title} (#{id})",
            id,
          ]
        end.to_h,
        'Other' => HudUtility2024.other_situation_options(as: :destination).map do |id, title|
          [
            "#{title} (#{id})",
            id,
          ]
        end.to_h,
      }
    end

    def available_disabilities
      HudUtility2024.disability_types.invert
    end

    def available_indefinite_disabilities
      HudUtility2024.no_yes_reasons_for_missing_data_options.invert
    end

    def available_dv_status
      HudUtility2024.no_yes_reasons_for_missing_data_options.invert
    end

    def available_currently_fleeing
      HudUtility2024.no_yes_reasons_for_missing_data_options.invert
    end

    def to_comparison
      comparison = deep_dup
      (comparison.start, comparison.end) = comparison_dates if comparison_pattern != :no_comparison_period
      comparison
    end

    private def comparison_dates
      case comparison_pattern
      when :prior_period
        prior_end = start_date - 1.days
        period_length = (end_date - start_date).to_i
        prior_start = prior_end - period_length.to_i.days
        [prior_start, prior_end]
      when :prior_year
        prior_end = end_date - 1.years
        prior_start = start_date - 1.years
        [prior_start, prior_end]
      when :prior_fiscal_year
        # find the 9/30 that precedes the end date
        prior_end = Date.new(end_date.year, 9, 30)
        prior_end -= 1.years if prior_end >= end_date
        prior_start = Date.new(prior_end.year - 1, 10, 1)
        [prior_start, prior_end]
      else
        [start_date, end_date]
      end
    end
  end
end
