###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# = GrdaWarehouse::ServiceHistoryEnrollment
#
# ServiceHistoryEnrollments flatten Hud Enrollments and related records to serve reporting needs. These records are
# generated automatically. There is a 1:1 correspondence with Hud Enrollment records
#   created by GrdaWarehouse::Tasks::ServiceHistory::Enrollment.find_each(&:rebuild_service_history!)
class GrdaWarehouse::ServiceHistoryEnrollment < GrdaWarehouseBase
  include RailsDrivers::Extensions
  include ArelHelper

  alias_attribute :entry_date, :first_date_in_program
  alias_attribute :exit_date, :last_date_in_program

  belongs_to :client, class_name: 'GrdaWarehouse::Hud::Client', inverse_of: :service_history_enrollments, autosave: false, optional: true
  belongs_to :project, class_name: 'GrdaWarehouse::Hud::Project', foreign_key: [:data_source_id, :project_id, :organization_id], primary_key: [:data_source_id, :ProjectID, :OrganizationID], inverse_of: :service_history_enrollments, autosave: false, optional: true
  belongs_to :organization, class_name: 'GrdaWarehouse::Hud::Organization', foreign_key: [:data_source_id, :organization_id], primary_key: [:data_source_id, :OrganizationID], inverse_of: :service_history_enrollments, autosave: false, optional: true
  belongs_to :enrollment, class_name: 'GrdaWarehouse::Hud::Enrollment', foreign_key: [:data_source_id, :enrollment_group_id, :project_id], primary_key: [:data_source_id, :EnrollmentID, :ProjectID], autosave: false, optional: true
  has_one :source_client, through: :enrollment, source: :client, autosave: false
  has_one :enrollment_coc_at_entry, through: :enrollment, autosave: false
  has_one :client_head_of_household, class_name: 'GrdaWarehouse::Hud::Client', primary_key: [:head_of_household_id, :data_source_id], foreign_key: [:PersonalID, :data_source_id], autosave: false
  belongs_to :data_source, autosave: false, optional: true
  belongs_to :processed_client, -> { where(routine: 'service_history') }, class_name: 'GrdaWarehouse::WarehouseClientsProcessed', foreign_key: :client_id, primary_key: :client_id, inverse_of: :service_history_enrollments, autosave: false, optional: true
  has_many :service_history_services, inverse_of: :service_history_enrollment, primary_key: [:id, :client_id], foreign_key: [:service_history_enrollment_id, :client_id]
  has_one :service_history_exit, -> { where(record_type: 'exit') }, class_name: 'GrdaWarehouse::ServiceHistoryEnrollment', primary_key: [:data_source_id, :project_id, :enrollment_group_id, :client_id], foreign_key: [:data_source_id, :project_id, :enrollment_group_id, :client_id]

  # Find the SHE for the head of household associated with this enrollment's household, if this is for th HoH, it returns itself
  has_one :service_history_enrollment_for_head_of_household, -> { where(head_of_household: true) }, class_name: 'GrdaWarehouse::ServiceHistoryEnrollment', primary_key: [:head_of_household_id, :project_id, :data_source_id], foreign_key: [:head_of_household_id, :project_id, :data_source_id], autosave: false
  # Find the non HoH SHEs associated with this enrollment's household, if this is not for the HoH, it will contain this enrollment
  has_many :other_household_service_history_enrollments, -> { where(head_of_household: false) }, class_name: 'GrdaWarehouse::ServiceHistoryEnrollment', primary_key: [:data_source_id, :project_id, :household_id], foreign_key: [:data_source_id, :project_id, :household_id], autosave: false
  has_many :household_enrollments, class_name: 'GrdaWarehouse::Hud::Enrollment', primary_key: [:data_source_id, :project_id, :household_id], foreign_key: [:data_source_id, :ProjectID, :HouseholdID], autosave: false

  # make a scope for every project type and a type? method for instances
  HudUtility2024.performance_reporting.each do |k, v|
    next unless k.is_a?(Symbol)

    scope k, -> { where project_type_column => v }
    define_method "#{k}?" do
      v.include? self.project_type # rubocop:disable Style/RedundantSelf
    end
  end

  scope :entry, -> { where record_type: 'entry' }
  # hide previous declaration of :exit (from Kernel), we'll use this one
  replace_scope :exit, -> { where record_type: 'exit' }
  scope :bed_night, -> { es_nbn }
  scope :night_by_night, -> { es_nbn }
  # the first date individuals entered a residential service
  scope :first_date, -> { where record_type: 'first' }

  def self.service_types
    service_types = ['service']
    service_types << 'extrapolated' if GrdaWarehouse::Config.get(:so_day_as_month)
  end
  scope :residential, -> {
    in_project_type(HudUtility2024.residential_project_type_ids)
  }

  scope :hud_residential, -> do
    hud_project_type(HudUtility2024.residential_project_type_ids)
  end

  scope :hud_non_residential, -> do
    joins(:project).merge(GrdaWarehouse::Hud::Project.hud_non_residential)
  end

  scope :residential_non_homeless, -> do
    r_non_homeless = HudUtility2024.residential_project_type_numbers_by_code[:ph] + HudUtility2024.residential_project_type_numbers_by_code[:th]
    in_project_type(r_non_homeless)
  end
  scope :hud_residential_non_homeless, -> do
    r_non_homeless = HudUtility2024.residential_project_type_numbers_by_code[:ph] + HudUtility2024.residential_project_type_numbers_by_code[:th]
    hud_project_type(r_non_homeless)
  end
  scope :permanent_housing, -> do
    project_types = HudUtility2024.residential_project_type_numbers_by_code.values_at(:ph).flatten
    in_project_type(project_types)
  end

  scope :homeless_sheltered, -> do
    in_project_type(HudUtility2024.homeless_sheltered_project_types)
  end
  scope :homeless_unsheltered, -> do
    in_project_type(HudUtility2024.homeless_unsheltered_project_types)
  end

  scope :ongoing, ->(on_date: Date.current) do
    at = arel_table
    where_closed = at[:first_date_in_program].lteq(on_date).
      and(at[:last_date_in_program].gt(on_date))
    where_open = at[:first_date_in_program].lteq(on_date).
      and(at[:last_date_in_program].eq(nil))
    where(where_closed.or(where_open))
  end

  scope :open_between, ->(start_date:, end_date:) do
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

  scope :homeless, ->(chronic_types_only: false) do
    if chronic_types_only
      project_types = HudUtility2024.chronic_project_types
    else
      project_types = HudUtility2024.homeless_project_types
    end
    in_project_type(project_types)
  end

  # this is always only chronic
  scope :hud_homeless, ->(chronic_types_only: true) do # rubocop:disable Lint/UnusedBlockArgument
    hud_project_type(HudUtility2024.chronic_project_types)
  end

  # The client is enrolled in ES, SO, SH (TH) or PH prior to move-in and has no overlapping PH (TH) after move in
  scope :currently_homeless, ->(date: Date.current, chronic_types_only: false) do
    if chronic_types_only # literally homeless
      residential_project_types = HudUtility2024.residential_project_type_numbers_by_code[:ph] + HudUtility2024.residential_project_type_numbers_by_code[:th]
    else
      residential_project_types = HudUtility2024.residential_project_type_numbers_by_code[:ph]
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

  scope :hud_currently_homeless, ->(date: Date.current, chronic_types_only: false) do
    if chronic_types_only # literally homeless
      residential_project_types = HudUtility2024.residential_project_type_numbers_by_code[:ph] + HudUtility2024.residential_project_type_numbers_by_code[:th]
    else
      residential_project_types = HudUtility2024.residential_project_type_numbers_by_code[:ph]
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

  scope :service_within_date_range, ->(start_date:, end_date:) do
    joins(:service_history_services).
      merge(GrdaWarehouse::ServiceHistoryService.service).
      where(shs_t[:date].gteq(start_date).and(shs_t[:date].lteq(end_date)))
  end

  scope :service_on_date, ->(date) do
    joins(:service_history_services).
      merge(GrdaWarehouse::ServiceHistoryService.service).
      where(shs_t[:date].eq(date))
  end

  scope :entry_within_date_range, ->(start_date:, end_date:) do
    self.entry.started_between(start_date: start_date, end_date: end_date) # rubocop:disable Style/RedundantSelf
  end

  scope :exit_within_date_range, ->(start_date:, end_date:) do
    self.entry.ended_between(start_date: start_date, end_date: end_date) # rubocop:disable Style/RedundantSelf
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

  scope :enrollment_open_in_prior_years, ->(years: 3) do
    lookback_date = DateTime.current - years.years
    open_between(start_date: lookback_date, end_date: Date.current)
  end

  scope :started_between, ->(start_date:, end_date:) do
    where(first_date_in_program: (start_date..end_date))
  end

  scope :ended_between, ->(start_date:, end_date:) do
    where(last_date_in_program: (start_date..end_date))
  end

  scope :coc_funded, -> do
    joins(:project).merge(GrdaWarehouse::Hud::Project.coc_funded)
  end

  # Takes advantage of the HUD reporting override for CoC code
  scope :in_coc, ->(coc_code:) do
    joins(project: :project_cocs).
      merge(GrdaWarehouse::Hud::ProjectCoc.in_coc(coc_code: coc_code))
  end

  scope :coc_funded_in, ->(coc_code:) do
    coc_funded.in_coc(coc_code: coc_code)
  end

  scope :in_zip, ->(zip_code:) do
    joins(project: :project_cocs).
      merge(GrdaWarehouse::Hud::ProjectCoc.in_zip(zip_code: zip_code))
  end

  scope :in_place, ->(place:) do
    joins(project: :project_cocs).
      merge(GrdaWarehouse::Hud::ProjectCoc.in_place(place: place))
  end

  scope :in_county, ->(county:) do
    joins(project: :project_cocs).
      merge(GrdaWarehouse::Hud::ProjectCoc.in_county(county: county))
  end

  # Category 3 is "Homeless only under other federal statuses" and
  # is defined as a housing status of value 5
  # TODO: updated this for FY2024 to not use cached values,
  # this appears to only be used in the SPM, so maybe we can just tear it out and use
  # source data there instead
  scope :category_3, -> do
    # pre FY2024 logic, remove after we confirm the new version works
    # where(
    #   arel_table[:housing_status_at_entry].eq(5).
    #     or(arel_table[:housing_status_at_exit].eq(5)),
    # )
    left_outer_joins(enrollment: :exit).
      where(e_t[:LivingSituation].eq(205).or(ex_t[:HousingAssessment].eq(5)))
  end

  scope :grant_funded_between, ->(start_date:, end_date:) do
    joins(project: :funders).
      merge(GrdaWarehouse::Hud::Funder.open_between(start_date: start_date, end_date: end_date))
  end

  # HUD reporting Project Type overlay
  # Now controlled by import overrides
  scope :hud_project_type, ->(project_types) do
    where(project_type: project_types)
  end

  scope :in_project_type, ->(project_types) do
    where(project_type: project_types)
  end

  # uses actual Projects.id not ProjectID (which is stored in the table and requires data_source_id)
  # also accepts an array of ids if you want a multi-project query
  scope :in_project, ->(ids) do
    joins(:project).merge(GrdaWarehouse::Hud::Project.where(id: ids))
  end

  scope :in_organization, ->(ids) do
    joins(:organization).merge(GrdaWarehouse::Hud::Organization.where(id: ids))
  end

  scope :in_data_source, ->(ids) do
    where(data_source_id: ids)
  end

  scope :with_service_between, ->(start_date:, end_date:, service_scope: :current_scope) do
    where(
      GrdaWarehouse::ServiceHistoryService.
      service_between(start_date: start_date, end_date: end_date, service_scope: service_scope).
      where(
        shs_t[:service_history_enrollment_id].eq(she_t[:id]).
        and(shs_t[:client_id].eq(she_t[:client_id])),
      ).
      arel.exists,
    )
    # joins(:service_history_services).
    #   merge(GrdaWarehouse::ServiceHistoryService.service_between(start_date: start_date, end_date: end_date, service_scope: service_scope))
    # where(GrdaWarehouse::ServiceHistoryService.where(
    #     shs_t[:service_history_enrollment_id].eq(arel_table[:id])
    #   ).
    #   where(date: start_date..end_date)).
    #   send(service_scope).
    #   exists)
  end

  scope :with_service, -> do
    where(
      GrdaWarehouse::ServiceHistoryService.
      where(
        shs_t[:service_history_enrollment_id].eq(she_t[:id]).
        and(shs_t[:client_id].eq(she_t[:client_id])),
      ).
      arel.exists,
    )
  end

  scope :heads_of_households, -> do
    where(she_t[:head_of_household].eq(true))
  end

  scope :visible_in_window_to, ->(user) do
    return none unless user.can_view_clients?

    joins(:enrollment).merge(GrdaWarehouse::Hud::Enrollment.visible_to(user))
  end

  scope :with_move_in_date_before, ->(date) do
    where(she_t[:move_in_date].lt(date))
  end

  scope :with_move_in_date_after_or_blank, ->(date) do
    where(she_t[:move_in_date].gteq(date).or(she_t[:move_in_date].eq(nil)))
  end

  scope :in_age_ranges, ->(age_ranges) do
    age_ranges = age_ranges.reject(&:blank?).map(&:to_sym)
    return current_scope unless age_ranges.present?

    age_exists = she_t[:age].not_eq(nil)
    age_ors = []
    age_ors << she_t[:age].lt(18) if age_ranges.include?(:under_eighteen)
    age_ors << she_t[:age].gteq(18).and(she_t[:age].lteq(24)) if age_ranges.include?(:eighteen_to_twenty_four)
    age_ors << she_t[:age].gteq(25).and(she_t[:age].lteq(61)) if age_ranges.include?(:twenty_five_to_sixty_one)
    age_ors << she_t[:age].gt(61) if age_ranges.include?(:over_sixty_one)

    accumulative = nil
    age_ors.each do |age|
      accumulative = if accumulative.present?
        accumulative.or(age)
      else
        age
      end
    end
    current_scope.where(age_exists.and(accumulative))
  end

  # NOTE: at the moment this is Postgres only
  # Arguments:
  #   an optional column, usually first_date_in_program or last_date_in_program
  #   an optional scope which is passed to the sub query that determines which record to return
  scope :only_most_recent_by_client, ->(column: :first_date_in_program, scope: nil) do
    one_for_column(column, source_arel_table: arel_table, group_on: :client_id, direction: :desc, scope: scope)
  end

  scope :on_cohort, ->(cohort_id:) do
    where(client_id: GrdaWarehouse::CohortClient.active.where(cohort_id: cohort_id).select(:client_id))
  end

  #################################
  # Standard Cohort Scopes

  # FIXME: do we need these? individual, youth, children, adult
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

  def self.known_standard_cohorts
    AvailableSubPopulations.available_sub_populations.values
  end

  # End Standard Cohort Scopes
  #################################

  # Only run this on off-hours.  It can take 2-5 hours and hang
  # the database
  def self.reindex_table!
    connection.execute("REINDEX TABLE #{table_name}")
  end

  def self.view_column_names
    column_names - [
      'date',
      'project_type',
      'organization_id',
      'service_type',
      'record_type',
      'housing_status_at_entry',
      'housing_status_at_exit',
      'presented_as_individual',
      'other_clients_over_25',
      'other_clients_under_18',
      'other_clients_between_18_and_25',
      'unaccompanied_youth',
      'parenting_youth',
      'parenting_juvenile',
      'children_only',
      'individual_adult',
      'individual_elder',
      'head_of_household',
      'unaccompanied_minor',
    ]
  end

  # Relevant Project Types/Program Types
  # 0: Emergency Shelter (ES Entry/Exit)
  # 1: Emergency Shelter (ES NBN)
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
  # 14: Coordinated Entry
  def service_type
    ::HudUtility2024.project_type(project_type)
  end

  def service_type_brief
    ::HudUtility2024.project_type_brief(project_type)
  end

  def start_time
    date
  end

  def so?
    self[self.class.project_type_column] == HudUtility2024.project_type_number('SO')
  end

  def ce?
    self[self.class.project_type_column] == HudUtility2024.project_type_number('CE')
  end

  def homeless?
    self[self.class.project_type_column].in?(HudUtility2024.homeless_project_types)
  end

  def nbn?
    es_nbn?
  end

  # How many distinct bed nights does the client have in this enrollment?
  # For entry/exit this is span, for night by night, this is service days.
  def bed_nights(end_date: nil)
    if nbn?
      end_date = [
        last_date_in_program.try(:-, 1.day), # Don't count a bed night that falls on the exit day
        end_date + 1.day, # Include a bed night that falls on the end date
      ].compact.min

      service_history_services.
        service_between(start_date: first_date_in_program, end_date: end_date).
        where(service_type: 200).
        select(:date).
        distinct.
        count
    else
      end_date = [
        last_date_in_program,
        end_date + 1.day,
      ].compact.min

      (end_date - first_date_in_program).to_i
    end
  end

  def self.project_type_column
    :project_type
  end

  def self.available_age_ranges
    {
      under_eighteen: '< 18',
      eighteen_to_twenty_four: '18 - 24',
      twenty_five_to_sixty_one: '25 - 61',
      over_sixty_one: '62+',
    }.invert.freeze
  end
end
