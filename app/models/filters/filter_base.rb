###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
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
    attribute :require_service_during_range, Boolean, default: true
    attribute :sort
    attribute :heads_of_household, Boolean, default: false
    attribute :comparison_pattern, Symbol, default: ->(r, _) { r.default_comparison_pattern }
    attribute :household_type, Symbol, default: :all
    attribute :hoh_only, Boolean, default: false
    attribute :project_type_codes, Array, default: ->(r, _) { r.default_project_type_codes }
    attribute :project_type_numbers, Array, default: ->(_r, _) { [] }
    attribute :veteran_statuses, Array, default: []
    attribute :age_ranges, Array, default: []
    attribute :genders, Array, default: []
    attribute :races, Array, default: []
    attribute :ethnicities, Array, default: []
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
    attribute :coc_codes, Array, default: []
    attribute :coc_code, String, default: GrdaWarehouse::Config.get(:site_coc_codes)
    attribute :sub_population, Symbol, default: :clients
    attribute :start_age, Integer, default: 17
    attribute :end_age, Integer, default: 25
    attribute :ph, Boolean, default: false
    attribute :disabilities, Array, default: []
    attribute :indefinite_disabilities, Array, default: []
    attribute :dv_status, Array, default: []
    attribute :currently_fleeing, Array, default: []
    attribute :chronic_status, Boolean, default: false
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

    validates_presence_of :start, :end

    # NOTE: keep this up-to-date if adding additional attributes
    def cache_key
      [
        user.id,
        effective_project_ids,
        cohort_ids,
        coc_codes,
        coc_code,
        sub_population,
        start_age,
        end_age,
        ph,
        project_type_codes,
        gender,
        race,
        ethnicity,
      ]
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
      self.coc_codes = filters.dig(:coc_codes)&.select { |code| available_coc_codes&.include?(code) }.presence || coc_codes.presence || user.coc_codes
      self.coc_code = filters.dig(:coc_code) if available_coc_codes&.include?(filters.dig(:coc_code))
      self.household_type = filters.dig(:household_type)&.to_sym || household_type
      unless filters.dig(:hoh_only).nil?
        filter_hoh = filters.dig(:hoh_only).in?(['1', 'true', true])
        self.heads_of_household = filter_hoh
        self.hoh_only = filter_hoh
      end
      if filters.key?(:project_type_codes)
        self.project_type_codes = Array.wrap(filters.dig(:project_type_codes))&.reject(&:blank?)
      elsif filters.key?(:project_type_numbers)
        self.project_type_codes = []
      else
        project_type_codes
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
      self.races = filters.dig(:races)&.select { |race| HUD.races(multi_racial: true).keys.include?(race) }.presence || races
      self.ethnicities = filters.dig(:ethnicities)&.reject(&:blank?)&.map(&:to_i).presence || ethnicities
      self.project_group_ids = filters.dig(:project_group_ids)&.reject(&:blank?)&.map(&:to_i).presence || project_group_ids
      self.prior_living_situation_ids = filters.dig(:prior_living_situation_ids)&.reject(&:blank?)&.map(&:to_i).presence || prior_living_situation_ids
      self.destination_ids = filters.dig(:destination_ids)&.reject(&:blank?)&.map(&:to_i).presence || destination_ids
      self.length_of_times = filters.dig(:length_of_times)&.reject(&:blank?)&.map(&:to_sym).presence || length_of_times
      self.cohort_ids = filters.dig(:cohort_ids)&.reject(&:blank?)&.map(&:to_i).presence || cohort_ids

      self.disabilities = filters.dig(:disabilities)&.reject(&:blank?)&.map(&:to_i).presence || disabilities
      self.indefinite_disabilities = filters.dig(:indefinite_disabilities)&.reject(&:blank?)&.map(&:to_i).presence || indefinite_disabilities
      self.dv_status = filters.dig(:dv_status)&.reject(&:blank?)&.map(&:to_i).presence || dv_status
      self.currently_fleeing = filters.dig(:currently_fleeing)&.reject(&:blank?)&.map(&:to_i).presence || currently_fleeing
      self.chronic_status = filters.dig(:chronic_status).in?(['1', 'true', true]) unless filters.dig(:chronic_status).nil?
      self.rrh_move_in = filters.dig(:rrh_move_in).in?(['1', 'true', true]) unless filters.dig(:rrh_move_in).nil?
      self.psh_move_in = filters.dig(:psh_move_in).in?(['1', 'true', true]) unless filters.dig(:psh_move_in).nil?
      self.first_time_homeless = filters.dig(:first_time_homeless).in?(['1', 'true', true]) unless filters.dig(:first_time_homeless).nil?
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
          ethnicities: ethnicities,
          project_group_ids: project_group_ids,
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
        coc_codes: [],
        project_types: [],
        project_type_codes: [],
        project_type_numbers: [],
        veteran_statuses: [],
        age_ranges: [],
        genders: [],
        races: [],
        ethnicities: [],
        data_source_ids: [],
        organization_ids: [],
        project_ids: [],
        funder_ids: [],
        project_group_ids: [],
        disability_summary_ids: [],
        destination_ids: [],
        disabilities: [],
        indefinite_disabilities: [],
        dv_status: [],
        currently_fleeing: [],
        prior_living_situation_ids: [],
        length_of_times: [],
        times_homeless_in_last_three_years: [],
      ]
    end

    def selected_params_for_display(single_date: false)
      {}.tap do |opts|
        if single_date
          opts['On Date'] = on
        else
          opts['Report Range'] = date_range_words
        end
        opts['Comparison Range'] = comparison_range_words if includes_comparison?
        opts['CoC Codes'] = chosen_coc_codes if coc_codes.present?
        opts['CoC Code'] = chosen_coc_code if coc_code.present?
        opts['Project Types'] = chosen_project_types
        opts['Sub-Population'] = chosen_sub_population
        opts['Data Sources'] = data_source_names if data_source_ids.any?
        opts['Organizations'] = organization_names if organization_ids.any?
        opts['Projects'] = project_names if project_ids.any?
        opts['Project Groups'] = project_groups if project_group_ids.any?
        opts['Funders'] = funder_names if funder_ids.any?
        opts['Heads of Household only?'] = 'Yes' if hoh_only
        opts['Household Type'] = chosen_household_type if household_type
        opts['Age Ranges'] = chosen_age_ranges if age_ranges.any?
        opts['Races'] = chosen_races if races.any?
        opts['Ethnicities'] = chosen_ethnicities if ethnicities.any?
        opts['Genders'] = chosen_genders if genders.any?
        opts['Veteran Statuses'] = chosen_veteran_statuses if veteran_statuses.any?
        opts['Length of Time'] = length_of_times if length_of_times.any?
        opts['Prior Living Situations'] = chosen_prior_living_situations if prior_living_situation_ids.any?
        opts['Destinations'] = chosen_destinations if destination_ids.any?
        opts['Disabilities'] = chosen_disabilities if disabilities.any?
        opts['Indefinite and Impairing Disabilities'] = chosen_indefinite_disabilities if indefinite_disabilities.any?
        opts['DV Status'] = chosen_dv_status if dv_status.any?
        opts['Currently Fleeing DV'] = chosen_currently_fleeing if currently_fleeing.any?
        opts['Chronically Homeless'] = 'Yes' if chronic_status
        opts['With RRH Move-in'] = 'Yes' if rrh_move_in
        opts['With PSH Move-in'] = 'Yes' if psh_move_in
        opts['Fist Time Homeless in Past Two Years'] = 'Yes' if first_time_homeless
        opts['Returned to Homelessness from Permanent Destination'] = 'Yes' if returned_to_homelessness_from_permanent_destination
        opts['CE Homeless'] = 'Yes' if coordinated_assessment_living_situation_homeless
        opts['Current Living Situation Homeless'] = 'Yes' if ce_cls_as_homeless
        opts['Client Limits'] = chosen_vispdat_limits if limit_to_vispdat != :all_clients
        opts['Times Homeless in Past 3 Years'] = chosen_times_homeless_in_last_three_years if times_homeless_in_last_three_years.any?
      end
    end

    def range
      start .. self.end
    end

    def as_date_range
      DateRange.new(start: start, end: self.end)
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
      "#{start_date} - #{end_date}"
    end

    def comparison_range_words
      s, e = comparison_dates
      "#{s} - #{e}"
    end

    def length
      (self.end - start).to_i
    rescue StandardError
      0
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

    def all_projects?
      effective_project_ids.sort == all_project_ids.sort
    end

    def project_ids
      @project_ids.reject(&:blank?)
    end

    def coc_codes
      @coc_codes.reject(&:blank?)
    end

    def project_group_ids
      @project_group_ids.reject(&:blank?)
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

    def effective_project_ids_from_projects
      @effective_project_ids_from_projects ||= project_ids.reject(&:blank?).map(&:to_i)
    end

    def effective_project_ids_from_project_groups
      projects = project_group_ids.reject(&:blank?).map(&:to_i)
      return [] if projects.empty?

      @effective_project_ids_from_project_groups ||= GrdaWarehouse::ProjectGroup.joins(:projects).
        merge(GrdaWarehouse::ProjectGroup.viewable_by(user)).
        where(id: projects).
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
      GrdaWarehouse::Hud::Project.viewable_by(user)
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
      GrdaWarehouse::ProjectGroup.joins(:projects).
        merge(all_project_scope)
    end

    # Select display options
    def project_type_options_for_select(id_limit: [])
      options = HUD.project_types.invert
      options = options.select { |_, id| id.in?(id_limit) } if id_limit.present?
      options.map do |text, id|
        [
          "#{text} (#{id})",
          id,
        ]
      end
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
      GrdaWarehouse::Cohort.viewable_by(user)
    end
    # End Select display options

    def clients_from_cohorts
      GrdaWarehouse::Hud::Client.joins(:cohort_clients).
        merge(GrdaWarehouse::CohortClient.active.where(cohort_id: cohort_ids)).
        distinct
    end

    def available_project_types
      GrdaWarehouse::Hud::Project::PROJECT_GROUP_TITLES.invert
    end

    def available_residential_project_types
      GrdaWarehouse::Hud::Project::RESIDENTIAL_TYPE_TITLES.invert
    end

    def available_homeless_project_types
      GrdaWarehouse::Hud::Project::HOMELESS_TYPE_TITLES.invert
    end

    def available_project_type_numbers
      ::HUD.project_types.invert
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
      ::HUD.times_homeless_options
    end

    def chosen_times_homeless_in_last_three_years
      available_times_homeless_in_last_three_years.invert[times_homeless_in_last_three_years]
    end

    def project_type_ids
      ids = GrdaWarehouse::Hud::Project::PERFORMANCE_REPORTING.values_at(
        *project_type_codes.reject(&:blank?).map(&:to_sym),
      ).flatten

      ids += project_type_numbers if project_type_numbers.any?
      ids
    end

    def selected_project_type_names
      GrdaWarehouse::Hud::Project::RESIDENTIAL_TYPE_TITLES.values_at(*project_type_codes.reject(&:blank?).map(&:to_sym))
    end

    def user
      @user ||= User.find(user_id)
    end

    def available_sub_populations
      AvailableSubPopulations.available_sub_populations
    end

    def available_age_ranges
      {
        under_eighteen: '< 18',
        eighteen_to_twenty_four: '18 - 24',
        twenty_five_to_twenty_nine: '25 - 29',
        thirty_to_thirty_nine: '30 - 39',
        forty_to_forty_nine: '40 - 49',
        fifty_to_fifty_four: '50 - 54',
        fifty_five_to_fifty_nine: '55 - 59',
        sixty_to_sixty_one: '60 - 61',
        over_sixty_one: '62+',
      }.invert.freeze
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
      }.invert.freeze
    end

    def clean_comparison_pattern(pattern)
      comparison_patterns.values.detect { |m| m == pattern&.to_sym } || comparison_pattern.presence || default_comparison_pattern
    end

    def available_coc_codes
      @available_coc_codes ||= begin
        cocs = GrdaWarehouse::Hud::ProjectCoc.distinct.pluck(:CoCCode, :hud_coc_code).flatten.map(&:presence).compact
        return cocs if user.system_user?

        # If a user has coc code limits assigned, enforce them
        cocs &= user&.coc_codes if user&.coc_codes.present?

        cocs
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
      return if last - first < 365

      self.end = first + 1.years - 1.days
    end

    def default_comparison_pattern
      :no_comparison_period
    end

    def includes_comparison?
      comparison_pattern != :no_comparison_period
    end

    def default_project_type_codes
      GrdaWarehouse::Hud::Project::HOMELESS_PROJECT_TYPE_CODES
    end

    def default_project_type_numbers
      GrdaWarehouse::Hud::Project::PROJECT_TYPES_WITH_INVENTORY
    end

    def describe_filter_as_html(keys = nil)
      describe_filter(keys).uniq.map do |(k, v)|
        content_tag(:div, class: 'report-parameters__parameter') do
          label = content_tag(:label, k, class: 'label label-default parameter-label')
          if v.is_a?(Array)
            count = v.count
            v = v.first(5)
            v << "#{count - 5} more" if count > 5
            v = v.to_sentence
          end
          label.concat(content_tag(:label, v, class: 'label label-primary parameter-value'))
        end
      end.join.html_safe
    end

    def describe_filter(keys = nil)
      [].tap do |descriptions|
        # only show "on" if explicitly chosen
        display_keys = for_params[:filters]
        display_keys.delete(:on) unless keys&.include?(:on)
        display_keys.each_key do |key|
          next if keys.present? && ! keys.include?(key)

          descriptions << describe(key)
        end
      end.compact
    end

    def describe(key, value = chosen(key))
      title = case key
      when :start
        'Report Range'
      when :end
        nil
      when :on
        'Date'
      when :comparison_pattern
        'Comparison Range' if includes_comparison?
      when :project_type_codes, :project_type_ids, :project_type_numbers
        'Project Type'
      when :sub_population
        'Sub-Population'
      when :age_ranges
        'Age Ranges'
      when :races
        'Races'
      when :ethnicities
        'Ethnicities'
      when :genders
        'Genders'
      when :coc_codes
        'CoCs'
      when :coc_code
        'CoC'
      when :organization_ids
        'Organizations'
      when :project_ids
        'Projects'
      when :data_source_ids
        'Data Sources'
      when :project_group_ids
        'Project Groups'
      when :funder_ids
        'Funding Sources'
      when :veteran_statuses
        'Veteran Status'
      when :household_type
        'Household Type'
      when :prior_living_situation_ids
        'Prior Living Situations'
      when :destination_ids
        'Destinations'
      when :disabilities
        'Disabilities'
      when :indefinite_disabilities
        'Indefinite Disability'
      when :dv_status
        'DV Status'
      when :currently_fleeing
        'Currently Fleeing DV'
      when :heads_of_household, :hoh_only
        'Heads of Household Only?'
      when :limit_to_vispdat
        value = nil if limit_to_vispdat == :all_clients
        'Client Limits'
      when :times_homeless_in_last_three_years
        'Times Homeless in Past 3 Years'
      end

      return unless value.present?

      [title, value]
    end

    def chosen(key)
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
      when :ethnicities
        chosen_ethnicities
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
      when :limit_to_vispdat
        chosen_vispdat_limits
      when :times_homeless_in_last_three_years
        chosen_times_homeless_in_last_three_years
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
        HUD.race(race, multi_racial: true)
      end
    end

    def chosen_ethnicities
      ethnicities.map do |ethnicity|
        HUD.ethnicity(ethnicity)
      end
    end

    def chosen_genders
      genders.map do |gender|
        HUD.gender(gender)
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

      GrdaWarehouse::Hud::Project.where(id: project_ids).pluck(:ProjectName)
    end

    def chosen_data_sources
      return nil unless data_source_ids.reject(&:blank?).present?

      GrdaWarehouse::DataSource.where(id: data_source_ids).pluck(:short_name)
    end

    def chosen_project_groups
      return nil unless project_group_ids.reject(&:blank?).present?

      GrdaWarehouse::ProjectGroup.where(id: project_group_ids).pluck(:name)
    end

    def chosen_funding_sources
      return nil unless funder_ids.reject(&:blank?).present?

      funder_ids.map { |code| "#{HUD.funding_source(code&.to_i)} (#{code})" }
    end

    def chosen_veteran_statuses
      veteran_statuses.map do |veteran_status|
        HUD.veteran_status(veteran_status)
      end
    end

    def chosen_project_types
      project_type_ids.map do |type|
        HUD.project_type(type)
      end.uniq
    end

    def chosen_project_types_only_homeless?
      project_type_ids.sort == GrdaWarehouse::Hud::Project::HOMELESS_PROJECT_TYPES.sort
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

    def chosen_currently_fleeing
      currently_fleeing.map do |id|
        available_currently_fleeing.invert[id]
      end.join(', ')
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

    def project_names
      project_options_for_select(user: user).
        values.
        flatten(1).
        select do |_, id|
          project_ids.include?(id)
        end&.map(&:first)
    end

    def project_groups
      project_groups_options_for_select(user: user).select { |_, id| project_group_ids.include?(id) }&.map(&:first)
    end

    def funder_names
      funder_options_for_select(user: user).select { |_, id| funder_ids.include?(id.to_i) }&.map(&:first)
    end

    def available_household_types
      {
        all: 'All household types',
        without_children: 'Adult only Households',
        with_children: 'Adult and Child Households',
        only_children: 'Child only Households',
      }.invert.freeze
    end

    def available_prior_living_situations
      HUD.living_situations.invert.map do |title, id|
        [
          "#{title} (#{id})",
          id,
        ]
      end.to_h
    end

    def available_destinations
      HUD.valid_destinations.invert
    end

    def available_disabilities
      HUD.disability_types.invert
    end

    def available_indefinite_disabilities
      HUD.no_yes_reasons_for_missing_data_options.invert
    end

    def available_dv_status
      HUD.no_yes_reasons_for_missing_data_options.invert
    end

    def available_currently_fleeing
      HUD.no_yes_reasons_for_missing_data_options.invert
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
      else
        [start_date, end_date]
      end
    end
  end
end
