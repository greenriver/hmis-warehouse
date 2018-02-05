class GrdaWarehouse::ServiceHistoryEnrollment < GrdaWarehouseBase
  include ArelHelper

  belongs_to :client, class_name: GrdaWarehouse::Hud::Client.name, inverse_of: :service_history_enrollments, autosave: false
  belongs_to :project, class_name: GrdaWarehouse::Hud::Project.name, foreign_key: [:data_source_id, :project_id, :organization_id], primary_key: [:data_source_id, :ProjectID, :OrganizationID], inverse_of: :service_history_enrollments, autosave: false
  belongs_to :organization, class_name: GrdaWarehouse::Hud::Organization.name, foreign_key: [:data_source_id, :organization_id], primary_key: [:data_source_id, :OrganizationID], inverse_of: :service_history_enrollments, autosave: false
  belongs_to :enrollment, class_name: GrdaWarehouse::Hud::Enrollment.name, foreign_key: [:data_source_id, :enrollment_group_id, :project_id], primary_key: [:data_source_id, :ProjectEntryID, :ProjectID], autosave: false
  has_one :source_client, through: :enrollment, source: :client, autosave: false
  has_one :enrollment_coc_at_entry, through: :enrollment, inverse_of: :service_history, autosave: false
  has_one :head_of_household, class_name: GrdaWarehouse::Hud::Client.name, primary_key: [:head_of_household_id, :data_source_id], foreign_key: [:PersonalID, :data_source_id], inverse_of: :service_history, autosave: false
  belongs_to :data_source, autosave: false
  belongs_to :processed_client, class_name: GrdaWarehouse::WarehouseClientsProcessed.name, foreign_key: :client_id, primary_key: :client_id, inverse_of: :service_history_enrollments, autosave: false
  has_many :service_history_services, inverse_of: :service_history_enrollment
  has_one :service_history_exit, -> { where(record_type: 'exit') }, class_name: GrdaWarehouse::ServiceHistoryEnrollment.name, primary_key: [:data_source_id, :project_id, :enrollment_group_id, :client_id], foreign_key: [:data_source_id, :project_id, :enrollment_group_id, :client_id]

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
    where(project_type_column => GrdaWarehouse::Hud::Project::RESIDENTIAL_PROJECT_TYPE_IDS)
  }

  scope :hud_residential, -> do
    hud_project_type(GrdaWarehouse::Hud::Project::RESIDENTIAL_PROJECT_TYPE_IDS)
  end

  scope :hud_non_residential, -> do
    joins(:project).merge(GrdaWarehouse::Hud::Project.hud_non_residential)
  end

  scope :residential_non_homeless, -> do
    r_non_homeless = GrdaWarehouse::Hud::Project::RESIDENTIAL_PROJECT_TYPE_IDS - GrdaWarehouse::Hud::Project::CHRONIC_PROJECT_TYPES
    where(project_type_column => r_non_homeless)
  end
  scope :hud_residential_non_homeless, -> do
    r_non_homeless = GrdaWarehouse::Hud::Project::RESIDENTIAL_PROJECT_TYPE_IDS - GrdaWarehouse::Hud::Project::CHRONIC_PROJECT_TYPES
    hud_project_type(r_non_homeless)
  end

  scope :ongoing, -> (on_date: Date.today) do
    at = arel_table
    where_closed = at[:first_date_in_program].lteq(on_date).
      and(at[:last_date_in_program].gt(on_date))
    where_open = at[:first_date_in_program].lteq(on_date).
      and(at[:last_date_in_program].eq(nil))
    where(where_closed.or(where_open))
  end

  # This is the old logic, still not completely convinced of the new logic
  # They do differ, but I believe the new logic is more correct
  scope :old_open_between, -> (start_date:, end_date:) do 
    at = arel_table

    closed_within_range = at[:last_date_in_program].gt(start_date).
      and(at[:first_date_in_program].lteq(end_date))
    opened_within_range = at[:first_date_in_program].gteq(start_date).
      and(at[:first_date_in_program].lt(end_date))
    open_throughout = at[:first_date_in_program].lt(start_date).
      and(at[:last_date_in_program].gt(start_date).
        or(at[:last_date_in_program].eq(nil))
      )
    where(closed_within_range.or(opened_within_range).or(open_throughout))
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

    where(project_type_column => project_types)
  end

  scope :hud_homeless, -> (chronic_types_only: false) do
    if chronic_types_only
      project_types = GrdaWarehouse::Hud::Project::CHRONIC_PROJECT_TYPES
    else
      project_types = GrdaWarehouse::Hud::Project::HOMELESS_PROJECT_TYPES
    end

    hud_project_type(GrdaWarehouse::Hud::Project::CHRONIC_PROJECT_TYPES)
  end

  scope :currently_homeless, -> (date: Date.today, chronic_types_only: false) do 
    if chronic_types_only
      project_types = GrdaWarehouse::Hud::Project::CHRONIC_PROJECT_TYPES
    else
      project_types = GrdaWarehouse::Hud::Project::HOMELESS_PROJECT_TYPES
    end
    non_homeless = GrdaWarehouse::Hud::Project::RESIDENTIAL_PROJECT_TYPE_IDS - project_types

    entry.
      ongoing(on_date: date).
      homeless.
      where.not(
        client_id: entry.ongoing(on_date: date).
          where(project_type_column => non_homeless).
          select(:client_id).
          distinct
      )
  end

  scope :hud_currently_homeless, -> (date: Date.today, chronic_types_only: false) do
    if chronic_types_only
      project_types = GrdaWarehouse::Hud::Project::CHRONIC_PROJECT_TYPES
    else
      project_types = GrdaWarehouse::Hud::Project::HOMELESS_PROJECT_TYPES
    end
    non_homeless = GrdaWarehouse::Hud::Project::RESIDENTIAL_PROJECT_TYPE_IDS - project_types

    entry.
      ongoing(on_date: date).
      hud_homeless.
      where.not(
        client_id: entry.ongoing(on_date: date).
          hud_project_type(non_homeless).
          select(:client_id).
          distinct
      )
  end

  scope :service_within_date_range, -> (start_date: , end_date: ) do
    joins(:service_history_services).
    merge(GrdaWarehouse::ServiceHistoryService.service).
    where(shs_t[:date].gteq(start_date).and(shs_t[:date].lteq(end_date)))
  end

  scope :entry_within_date_range, -> (start_date: , end_date: ) do
    entry.open_between(start_date: start_date, end_date: end_date)
  end

  scope :service_in_last_three_years, -> {
    service_within_date_range(start_date: 3.years.ago.to_date, end_date: Date.today)
  }
  scope :entry_in_last_three_years, -> {
    entry_within_date_range(start_date: 3.years.ago.to_date, end_date: Date.today)
  }
  scope :enrollments_open_in_last_three_years, -> {
    t = DateTime.current - 3.years
    at = arel_table
    where(
      at[:last_date_in_program].eq(nil).or(at[:first_date_in_program].gt(t)).or(at[:last_date_in_program].gt(t))
    )
  }

  scope :started_between, -> (start_date: , end_date: ) do
    where(first_date_in_program: (start_date..end_date))
  end

  scope :ended_between, -> (start_date: , end_date: ) do
    at = arel_table
    where(at[:last_date_in_program].gteq(start_date).and(at[:last_date_in_program].lteq(end_date)))
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

  scope :with_service_between, -> (start_date: ,end_date: ) do
    where(
      GrdaWarehouse::ServiceHistoryService.where( 
        shs_t[:service_history_enrollment_id].eq(arel_table[:id])
      ).
      where(date: (start_date..end_date)).
      exists
    )
  end

  scope :visible_in_window, -> do
    joins(:data_source).where(data_sources: {visible_in_window: true})
  end

  #################################
    # Standard Cohort Scopes
    scope :veteran, -> do
      joins(:client).merge(GrdaWarehouse::Hud::Client.veteran)
    end

    scope :non_veteran, -> do
      joins(:client).merge(GrdaWarehouse::Hud::Client.non_veteran)
    end

    scope :family, -> do
      where(presented_as_individual: false)
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
      where(she_t[:age].gteq(18))
    end

    # Client age on date is 18-24
    # Presented alone or as the head of household with no one else > 24
    scope :unaccompanied_youth, -> do
      where(unaccompanied_youth: true)
    end

    scope :parenting_youth, -> do
      where(parenting_youth: true)
    end

    scope :children_only, -> do
      where(children_only: true)
    end

    scope :parenting_juvenile, -> do
      where(parenting_juvenile: true)
    end

    scope :individual_adult, -> do
      individual.adult
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
    case project_type
    when 1
      'Emergency Shelter (ES)'
    when 2
      'Transitional Housing (TH)'
    when 3
      'Permanent Supportive Housing (PH)'
    when 4
      'Street Outreach (SO)'
    when 6
      'Services Only'
    when 7
      'Other'
    when 8
      'Safe Haven (SH)'
    when 9
      'Permanent Housing (Housing Only) (PH)'
    when 10
      'Permanent Housing (Housing with Services) (PH)'
    when 11
      'Day Shelter'
    when 12
      'Homeless Prevention'
    when 13
      'Rapid Re-Housing (PH)'
    when 14
      'Coordinated Assessment'
    end
  end

  def service_type_brief
    ::HUD.project_type_brief(project_type)
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