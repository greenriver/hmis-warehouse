class GrdaWarehouse::ServiceHistory < GrdaWarehouseBase
  self.table_name = 'warehouse_client_service_history'

  belongs_to :client, class_name: GrdaWarehouse::Hud::Client.name, inverse_of: :service_history
  belongs_to :project, class_name: GrdaWarehouse::Hud::Project.name, foreign_key: [:data_source_id, :project_id, :organization_id], primary_key: [:data_source_id, :ProjectID, :OrganizationID]
  belongs_to :organization, class_name: GrdaWarehouse::Hud::Organization.name, foreign_key: [:data_source_id, :organization_id], primary_key: [:data_source_id, :OrganizationID]
  belongs_to :enrollment, class_name: GrdaWarehouse::Hud::Enrollment.name, foreign_key: [:data_source_id, :enrollment_group_id, :project_id], primary_key: [:data_source_id, :ProjectEntryID, :ProjectID], inverse_of: :service_histories
  has_one :enrollment_coc_at_entry, through: :enrollment
  belongs_to :data_source
  belongs_to :processed_client, class_name: GrdaWarehouse::WarehouseClientsProcessed.name, foreign_key: :client_id, primary_key: :client_id

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
  scope :service, -> { where record_type: 'service' }
  scope :bed_night, -> { where project_tracking_method: 3}
  # the first date individuals entered a residential service
  scope :first_date, -> { where record_type: 'first' }
  scope :residential, -> {
    where(project_type_column => GrdaWarehouse::Hud::Project::RESIDENTIAL_PROJECT_TYPE_IDS)
  }

  scope :hud_residential, -> do
    hud_project_type(GrdaWarehouse::Hud::Project::RESIDENTIAL_PROJECT_TYPE_IDS)
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
    where(d_2_end.gt(d_1_start).or(d_2_end.eq(nil)).and(d_2_start.lt(d_1_end)))
  end

  # identical to the above but taking a bunch of pairs of dates instead of a single pair
  scope :open_between_any, -> (pairs_of_dates) do
    at = arel_table
    condition, *conditions = pairs_of_dates.map do |s1, e1|
      s2 = at[:first_date_in_program]
      e2 = at[:last_date_in_program]
      s2.lt(e1).and( e2.gt(s1).or( e2.eq nil ) )
    end
    condition = conditions.reduce(condition){ |c1, c2| c1.or c2 } # a disjunction of all date ranges
    where condition
  end

  scope :homeless, -> do
    where(project_type_column => GrdaWarehouse::Hud::Project::CHRONIC_PROJECT_TYPES)
  end
  scope :hud_homeless, -> do
    hud_project_type(GrdaWarehouse::Hud::Project::CHRONIC_PROJECT_TYPES)
  end

  scope :currently_homeless, -> (date: Date.today) do 
    # Limit currently homeless to ES, SH, SO since PSH and TH etc. are 
    # technically housed
    non_homeless = GrdaWarehouse::Hud::Project::RESIDENTIAL_PROJECT_TYPE_IDS - GrdaWarehouse::Hud::Project::CHRONIC_PROJECT_TYPES

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

  scope :hud_currently_homeless, -> (date: Date.today) do
    # Limit currently homeless to ES, SH, SO since PSH and TH etc. are 
    # technically housed
    non_homeless = GrdaWarehouse::Hud::Project::RESIDENTIAL_PROJECT_TYPE_IDS - GrdaWarehouse::Hud::Project::CHRONIC_PROJECT_TYPES

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
    at = arel_table
    service.where(at[:date].gteq(start_date).and(at[:date].lteq(end_date)))
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
    at = arel_table
    where(at[:first_date_in_program].gteq(start_date).and(at[:first_date_in_program].lt(end_date)))
  end

  scope :ended_between, -> (start_date: , end_date: ) do
    at = arel_table
    where(at[:last_date_in_program].gteq(start_date).and(at[:last_date_in_program].lt(end_date)))
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
    # pt = GrdaWarehouse::Hud::Project.arel_table
    # sht = arel_table
    # joins(:project).
    # where(
    #   pt[:act_as_project_type].eq(nil).
    #   and(sht[:project_type].in(project_types)).
    #   or(pt[:act_as_project_type].in(project_types)))
    # '(Project.act_as_project_type is null and project_type in (?)) or Project.act_as_project_type in (?)'
  end

  scope :visible_in_window, -> do
    joins(:data_source).where(data_sources: {visible_in_window: true})
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