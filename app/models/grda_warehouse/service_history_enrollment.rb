###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

class GrdaWarehouse::ServiceHistoryEnrollment < GrdaWarehouseBase
  include ArelHelper

  belongs_to :client, class_name: 'GrdaWarehouse::Hud::Client', inverse_of: :service_history_enrollments, autosave: false
  belongs_to :project, class_name: 'GrdaWarehouse::Hud::Project', foreign_key: [:data_source_id, :project_id, :organization_id], primary_key: [:data_source_id, :ProjectID, :OrganizationID], inverse_of: :service_history_enrollments, autosave: false
  belongs_to :organization, class_name: 'GrdaWarehouse::Hud::Organization', foreign_key: [:data_source_id, :organization_id], primary_key: [:data_source_id, :OrganizationID], inverse_of: :service_history_enrollments, autosave: false
  belongs_to :enrollment, class_name: 'GrdaWarehouse::Hud::Enrollment', foreign_key: [:data_source_id, :enrollment_group_id, :project_id], primary_key: [:data_source_id, :EnrollmentID, :ProjectID], autosave: false
  has_one :source_client, through: :enrollment, source: :client, autosave: false
  has_one :enrollment_coc_at_entry, through: :enrollment, autosave: false
  has_one :head_of_household, class_name: 'GrdaWarehouse::Hud::Client', primary_key: [:head_of_household_id, :data_source_id], foreign_key: [:PersonalID, :data_source_id], autosave: false
  belongs_to :data_source, autosave: false
  belongs_to :processed_client, -> { where(routine: 'service_history')}, class_name: 'GrdaWarehouse::WarehouseClientsProcessed', foreign_key: :client_id, primary_key: :client_id, inverse_of: :service_history_enrollments, autosave: false
  has_many :service_history_services, inverse_of: :service_history_enrollment
  has_one :service_history_exit, -> { where(record_type: 'exit') }, class_name: 'GrdaWarehouse::ServiceHistoryEnrollment', primary_key: [:data_source_id, :project_id, :enrollment_group_id, :client_id], foreign_key: [:data_source_id, :project_id, :enrollment_group_id, :client_id]

  # make a scope for every project type and a type? method for instances
  GrdaWarehouse::Hud::Project::RESIDENTIAL_PROJECT_TYPES.each do |k,v|
    next unless Symbol === k
    scope k, -> { where project_type_column => v }
    define_method "#{k}?" do
      v.include? self.project_type
    end
  end

  scope :entry, -> { where record_type: 'entry' }
  scope :exit, -> { where record_type: 'exit' }
  scope :bed_night, -> { where project_tracking_method: 3 }
  scope :night_by_night, -> { bed_night }
  # the first date individuals entered a residential service
  scope :first_date, -> { where record_type: 'first' }

  def self.service_types
    service_types = ['service']
    if GrdaWarehouse::Config.get(:so_day_as_month)
      service_types << 'extrapolated'
    end
  end
  scope :residential, -> {
    in_project_type(GrdaWarehouse::Hud::Project::RESIDENTIAL_PROJECT_TYPE_IDS)
  }

  scope :hud_residential, -> do
    hud_project_type(GrdaWarehouse::Hud::Project::RESIDENTIAL_PROJECT_TYPE_IDS)
  end

  scope :hud_non_residential, -> do
    joins(:project).merge(GrdaWarehouse::Hud::Project.hud_non_residential)
  end

  scope :residential_non_homeless, -> do
    r_non_homeless = GrdaWarehouse::Hud::Project::RESIDENTIAL_PROJECT_TYPES[:ph] + GrdaWarehouse::Hud::Project::RESIDENTIAL_PROJECT_TYPES[:th]
    in_project_type(r_non_homeless)
  end
  scope :hud_residential_non_homeless, -> do
    r_non_homeless = GrdaWarehouse::Hud::Project::RESIDENTIAL_PROJECT_TYPES[:ph] + GrdaWarehouse::Hud::Project::RESIDENTIAL_PROJECT_TYPES[:th]
    hud_project_type(r_non_homeless)
  end
  scope :permanent_housing, -> do
    project_types = GrdaWarehouse::Hud::Project::RESIDENTIAL_PROJECT_TYPES.values_at(:ph).flatten
    in_project_type(project_types)
  end

  scope :homeless_sheltered, -> do
    in_project_type(GrdaWarehouse::Hud::Project::HOMELESS_SHELTERED_PROJECT_TYPES)
  end
  scope :homeless_unsheltered, -> do
    in_project_type(GrdaWarehouse::Hud::Project::HOMELESS_UNSHELTERED_PROJECT_TYPES)
  end

  scope :ongoing, -> (on_date: Date.current) do
    at = arel_table
    where_closed = at[:first_date_in_program].lteq(on_date).
      and(at[:last_date_in_program].gt(on_date))
    where_open = at[:first_date_in_program].lteq(on_date).
      and(at[:last_date_in_program].eq(nil))
    where(where_closed.or(where_open))
  end

  scope :open_between, -> (start_date:, end_date:) do
    at = arel_table
    # Excellent discussion of why this works:
    # http://stackoverflow.com/questions/325933/determine-whether-two-date-ranges-overlap
    d_1_start = start_date
    d_1_end = end_date
    d_2_start = at[:first_date_in_program]
    d_2_end = at[:last_date_in_program]
    # Currently does not count as an overlap if one starts on the end of the other
    where(d_2_end.gteq(d_1_start).or(d_2_end.eq(nil)).and(d_2_start.lteq(d_1_end)))
  end

  scope :homeless, -> (chronic_types_only: false) do
    if chronic_types_only
      project_types = GrdaWarehouse::Hud::Project::CHRONIC_PROJECT_TYPES
    else
      project_types = GrdaWarehouse::Hud::Project::HOMELESS_PROJECT_TYPES
    end
    in_project_type(project_types)
  end

  # this is always only chronic
  scope :hud_homeless, -> (chronic_types_only: true) do
    hud_project_type(GrdaWarehouse::Hud::Project::CHRONIC_PROJECT_TYPES)
  end

  # The client is enrolled in ES, SO, SH (TH) or PH prior to move-in and has no overlapping PH (TH) after move in
  scope :currently_homeless, -> (date: Date.current, chronic_types_only: false) do

    if chronic_types_only # literally homeless
      residential_project_types = GrdaWarehouse::Hud::Project::RESIDENTIAL_PROJECT_TYPES[:ph] + GrdaWarehouse::Hud::Project::RESIDENTIAL_PROJECT_TYPES[:th]
    else
      residential_project_types = GrdaWarehouse::Hud::Project::RESIDENTIAL_PROJECT_TYPES[:ph]
    end

    homeless_scope = entry.
      ongoing(on_date: date).
      homeless(chronic_types_only: chronic_types_only)

    housed_scope = entry.ongoing(on_date: date).
      in_project_type(residential_project_types).
      with_move_in_date_before(date)

    where(id: homeless_scope).
      where.not(client_id: housed_scope.select(:client_id))
  end

  scope :hud_currently_homeless, -> (date: Date.current, chronic_types_only: false) do

    if chronic_types_only # literally homeless
      residential_project_types = GrdaWarehouse::Hud::Project::RESIDENTIAL_PROJECT_TYPES[:ph] + GrdaWarehouse::Hud::Project::RESIDENTIAL_PROJECT_TYPES[:th]
    else
      residential_project_types = GrdaWarehouse::Hud::Project::RESIDENTIAL_PROJECT_TYPES[:ph]
    end
    homeless_scope = entry.
      ongoing(on_date: date).
      homeless(chronic_types_only: chronic_types_only)

    housed_scope = entry.ongoing(on_date: date).
      hud_project_type(residential_project_types).
      with_move_in_date_before(date)

    where(id: homeless_scope).
      where.not(client_id: housed_scope.select(:client_id))
  end

  scope :service_within_date_range, -> (start_date: , end_date: ) do
    joins(:service_history_services).
    merge(GrdaWarehouse::ServiceHistoryService.service).
    where(shs_t[:date].gteq(start_date).and(shs_t[:date].lteq(end_date)))
  end

  scope :service_on_date, -> (date) do
    joins(:service_history_services).
      merge(GrdaWarehouse::ServiceHistoryService.service).
      where(shs_t[:date].eq(date))
  end

  scope :entry_within_date_range, -> (start_date: , end_date: ) do
    self.entry.started_between(start_date: start_date, end_date: end_date)
  end

  scope :exit_within_date_range, -> (start_date: , end_date: ) do
    self.exit.ended_between(start_date: start_date, end_date: end_date)
  end

  scope :service_in_last_three_years, -> {
    service_within_date_range(start_date: 3.years.ago.to_date, end_date: Date.current)
  }
  scope :entry_in_last_three_years, -> {
    entry_within_date_range(start_date: 3.years.ago.to_date, end_date: Date.current)
  }
  scope :enrollments_open_in_last_three_years, -> {
    enrollment_open_in_prior_years(years: 3)
  }

  scope :enrollment_open_in_prior_years, -> (years: 3) do
    t = DateTime.current - years.years
    at = arel_table
    where(
      at[:last_date_in_program].eq(nil).or(at[:first_date_in_program].gt(t)).or(at[:last_date_in_program].gt(t))
    )
  end

  scope :started_between, -> (start_date: , end_date: ) do
    where(first_date_in_program: [start_date..end_date])
  end

  scope :ended_between, -> (start_date: , end_date: ) do
    where(last_date_in_program: [start_date..end_date])
  end

  scope :coc_funded, -> do
    joins(:project).merge(GrdaWarehouse::Hud::Project.coc_funded)
  end

  # Takes advantage of the HUD reporting override for CoC code
  scope :in_coc, -> (coc_code:) do
    joins(project: :project_cocs).
      merge(GrdaWarehouse::Hud::ProjectCoc.in_coc(coc_code: coc_code))
  end

  scope :coc_funded_in, -> (coc_code:) do
    coc_funded.in_coc(coc_code: coc_code)
  end

  # Category 3 is "Homeless only under other federal statuses" and
  # is defined as a housing status of value 5
  scope :category_3, -> do
    where(arel_table[:housing_status_at_entry].eq(5).
      or(arel_table[:housing_status_at_exit].eq(5))
    )
  end

  scope :grant_funded_between, -> (start_date:, end_date:) do
    joins(project: :funders).
      merge(GrdaWarehouse::Hud::Funder.open_between(start_date: start_date, end_date: end_date))
  end

  # HUD reporting Project Type overlay
  scope :hud_project_type, -> (project_types) do
    where(computed_project_type: project_types)
  end

  scope :in_project_type, -> (project_types) do
    where(project_type_column => project_types)
  end

  # uses actual Projects.id not ProjectID (which is stored in the table and requires data_source_id)
  # also accepts an array of ids if you want a multi-project query
  scope :in_project, -> (ids) do
    joins(:project).merge(GrdaWarehouse::Hud::Project.where(id: ids))
  end

  scope :in_organization, -> (ids) do
    joins(:organization).merge(GrdaWarehouse::Hud::Organization.where(id: ids))
  end

  scope :in_data_source, -> (ids) do
    where(data_source_id: ids)
  end

  scope :with_service_between, -> (start_date:, end_date:, service_scope: :current_scope) do
    joins(:service_history_services).
      merge(GrdaWarehouse::ServiceHistoryService.service_between(start_date: start_date, end_date: end_date, service_scope: service_scope))
    # where(GrdaWarehouse::ServiceHistoryService.where(
    #     shs_t[:service_history_enrollment_id].eq(arel_table[:id])
    #   ).
    #   where(date: start_date..end_date)).
    #   send(service_scope).
    #   exists)
  end

  scope :heads_of_households, -> do
    where(she_t[:head_of_household].eq(true))
  end

  scope :visible_in_window_to, -> (user) do
    joins(:data_source).merge(GrdaWarehouse::DataSource.visible_in_window_to(user))
  end

  scope :with_move_in_date_before, -> (date) do
    where(she_t[:move_in_date].lt(date))
  end

  scope :with_move_in_date_after_or_blank, -> (date) do
    where(she_t[:move_in_date].gteq(date).or(she_t[:move_in_date].eq(nil)))
  end

  #################################
    # Standard Cohort Scopes
    scope :all_clients, -> do
      all
    end

    scope :veteran, -> do
      joins(:client).merge(GrdaWarehouse::Hud::Client.veteran)
    end
    scope :veterans, -> do
      veteran
    end

    scope :non_veteran, -> do
      joins(:client).merge(GrdaWarehouse::Hud::Client.non_veteran)
    end
    scope :non_veterans, -> do
      veteran
    end

    scope :family_parents, -> do
      # Client is the head of household
      family.where(she_t[:head_of_household].eq(true))
    end

    scope :family, -> do
      if GrdaWarehouse::Config.get(:family_calculation_method) == 'multiple_people'
        where(presented_as_individual: false)
      else
        a_t = arel_table
        where(
          # Client is in enrollment household with more than one member
          a_t[:presented_as_individual].eq(false).
          # client is adult, and there are kids
          and(
            a_t[:age].gt(17).and(a_t[:other_clients_under_18].gt(0))
          ).
          # client is a child and there are adults
          or(
            a_t[:age].lt(18).
            and(a_t[:other_clients_between_18_and_25].gt(0).
            or(a_t[:other_clients_over_25].gt(0)))
          )
        )
      end
    end
    scope :youth_families, -> do
      if GrdaWarehouse::Config.get(:family_calculation_method) == 'multiple_people'
        where(
          presented_as_individual: false,
          age: 0..25,
          other_clients_over_25: 0,
        )
      else
        a_t = arel_table
        where(
          # Client is in enrollment household with more than one member
          # At least one person 18-25 and one under 18
          a_t[:presented_as_individual].eq(false).
          # client is a youth (18-24), and there are kids
          and(
            a_t[:age].gt(17).
            and(a_t[:age].lt(25)).
            and(a_t[:other_clients_under_18].gt(0)).
            and(a_t[:other_clients_over_25].eq(0))
          ).
          # client is a child and there are adults, but no one over 25
          or(
            a_t[:age].lt(18).
            and(a_t[:other_clients_between_18_and_25].gt(0).
            or(a_t[:other_clients_over_25].eq(0)))
          )
        )
      end
    end

    scope :individual, -> do
      where(presented_as_individual: true)
    end

    scope :youth, -> do
      where(age: (18..24))
    end

    scope :children, -> do
      where(age: (0...18))
    end

    scope :adult, -> do
      where(age: (18..Float::INFINITY))
    end

    # Client age on date is 18-24
    # Presented alone or as the head of household with no one else > 24
    scope :unaccompanied_youth, -> do
      where(unaccompanied_youth: true)
    end

    scope :parenting_youth, -> do
      where(parenting_youth: true).
      where(she_t[:head_of_household].eq(true))
    end

    scope :children_only, -> do
      where(children_only: true)
    end

    scope :parenting_juvenile, -> do
      where(parenting_juvenile: true).
      where(she_t[:head_of_household].eq(true))
    end
    scope :parenting_children, -> do
      parenting_juvenile
    end

    scope :unaccompanied_minors, -> do
      where(unaccompanied_minor: true)
    end

    scope :individual_adult, -> do
      individual.adult
    end

    scope :individual_adults, -> do
      individual.adult
    end

    def self.know_standard_cohorts
      [
        :all_clients,
        :veteran,
        :non_veteran,
        :family,
        :youth_families,
        :individual,
        :youth,
        :children,
        :adult,
        :unaccompanied_youth,
        :family_parents,
        :parenting_youth,
        :children_only,
        :parenting_juvenile,
        :parenting_children,
        :unaccompanied_minors,
        :individual_adult,
        :individual_adults,
      ]
    end


    # End Standard Cohort Scopes
    #################################

  # Only run this on off-hours.  It can take 2-5 hours and hang
  # the database
  def self.reindex_table!
    connection.execute("REINDEX TABLE #{table_name}")
  end

  # Relevant Project Types/Program Types
  # 1: Emergency Shelter (ES)
  # 2: Transitional Housing (TH)
  # 3: Permanent Supportive Housing (disability required for entry) (PH)
  # 4: Street Outreach (SO)
  # 6: Services Only
  # 7: Other
  # 8: Safe Haven (SH)
  # 9: Permanent Housing (Housing Only) (PH)
  # 10: Permanent Housing (Housing with Services - no disability required for entry) (PH)
  # 11: Day Shelter
  # 12: Homeless Prevention
  # 13: Rapid Re-Housing (PH)
  # 14: Coordinated Assessment
  def service_type
    ::HUD.project_type(computed_project_type)
  end

  def service_type_brief
    ::HUD.project_type_brief(computed_project_type)
  end

  def start_time
    date
  end

  def self.project_type_column
    if GrdaWarehouse::Config.get(:project_type_override)
      :computed_project_type
    else
      :project_type
    end
  end
end