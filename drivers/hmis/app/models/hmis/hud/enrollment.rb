###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class Hmis::Hud::Enrollment < Hmis::Hud::Base
  include ::HmisStructure::Enrollment
  include ::Hmis::Hud::Concerns::Shared
  include ::HudConcerns::Enrollment
  include ::Hmis::Hud::Concerns::HasCustomDataElements
  include ::Hmis::Hud::Concerns::ServiceHistoryQueuer

  self.table_name = :Enrollment
  self.sequence_name = "public.\"#{table_name}_id_seq\""

  has_paper_trail(
    meta: {
      enrollment_id: :id,
      client_id: ->(r) { r.client&.id },
      project_id: ->(r) { r.project&.id },
    },
  )

  belongs_to :data_source, class_name: 'GrdaWarehouse::DataSource'

  attr_accessor :in_progress

  delegate :exit_date, to: :exit, allow_nil: true

  # CAUTION: unlike the warehouse models, the HMIS Enrollment-to-Project relationship does not use the HUD ProjectID
  # field. It uses a conventional db PK relationship "Enrollment.project_pk" instead. This allows us to have
  # enrollments in a "WIP" or in-progress state; these wip enrollments have a NULL ProjectID but are still related via
  # the project pk
  belongs_to :project, foreign_key: :project_pk, optional: true, class_name: 'Hmis::Hud::Project'

  has_one :exit, **hmis_enrollment_relation('Exit'), inverse_of: :enrollment, dependent: :destroy

  # HUD services
  has_many :services, **hmis_enrollment_relation('Service'), inverse_of: :enrollment, dependent: :destroy
  has_many :bed_nights, -> { bed_nights }, **hmis_enrollment_relation('Service')
  # Custom services
  has_many :custom_services, **hmis_enrollment_relation('CustomService'), inverse_of: :enrollment, dependent: :destroy
  has_many :custom_case_notes, **hmis_enrollment_relation('CustomCaseNote'), inverse_of: :enrollment, dependent: :destroy
  # All services (combined view of HUD and Custom services)
  has_many :hmis_services, **hmis_enrollment_relation('HmisService'), inverse_of: :enrollment
  has_many(
    :move_in_addresses,
    -> { where(enrollment_address_type: Hmis::Hud::CustomClientAddress::ENROLLMENT_MOVE_IN_TYPE) },
    **hmis_relation(:EnrollmentID, 'CustomClientAddress'),
    inverse_of: :enrollment,
    dependent: :destroy,
  )

  has_many :events, **hmis_enrollment_relation('Event'), inverse_of: :enrollment, dependent: :destroy
  has_many :income_benefits, **hmis_enrollment_relation('IncomeBenefit'), inverse_of: :enrollment, dependent: :destroy
  has_many :disabilities, **hmis_enrollment_relation('Disability'), inverse_of: :enrollment, dependent: :destroy
  has_many :health_and_dvs, **hmis_enrollment_relation('HealthAndDv'), inverse_of: :enrollment, dependent: :destroy
  has_many :current_living_situations, **hmis_enrollment_relation('CurrentLivingSituation'), inverse_of: :enrollment, dependent: :destroy
  has_many :employment_educations, **hmis_enrollment_relation('EmploymentEducation'), inverse_of: :enrollment, dependent: :destroy
  has_many :youth_education_statuses, **hmis_enrollment_relation('YouthEducationStatus'), inverse_of: :enrollment, dependent: :destroy

  # CE Assessments
  has_many :assessments, **hmis_enrollment_relation('Assessment'), inverse_of: :enrollment, dependent: :destroy
  # Custom Assessments
  has_many :custom_assessments, **hmis_enrollment_relation('CustomAssessment'), inverse_of: :enrollment, dependent: :destroy
  has_one :intake_assessment, -> { intakes }, **hmis_enrollment_relation('CustomAssessment')
  has_one :exit_assessment, -> { exits }, **hmis_enrollment_relation('CustomAssessment')
  has_many :update_assessments, -> { updates }, **hmis_enrollment_relation('CustomAssessment')
  has_many :annual_assessments, -> { annuals }, **hmis_enrollment_relation('CustomAssessment')
  has_many :post_exit_assessments, -> { post_exits }, **hmis_enrollment_relation('CustomAssessment')

  # Files
  has_many :files, class_name: '::Hmis::File', dependent: :destroy, inverse_of: :enrollment

  belongs_to :client, **hmis_relation(:PersonalID, 'Client')
  belongs_to :user, **hmis_relation(:UserID, 'User'), optional: true, inverse_of: :enrollments
  belongs_to :household, **hmis_relation(:HouseholdID, 'Household'), inverse_of: :enrollments, optional: true

  # Unit occupancy
  # All unit occupancies, including historical
  has_many :unit_occupancies, class_name: 'Hmis::UnitOccupancy', inverse_of: :enrollment, dependent: :destroy
  has_one :active_unit_occupancy, -> { active }, class_name: 'Hmis::UnitOccupancy', inverse_of: :enrollment
  has_one :current_unit, through: :active_unit_occupancy, class_name: 'Hmis::Unit', source: :unit

  accepts_nested_attributes_for :move_in_addresses, allow_destroy: true

  before_validation :set_hud_project_id_from_project_pk_unless_wip, if: :project_pk_changed?
  def set_hud_project_id_from_project_pk_unless_wip
    return unless project_id

    self.project_id = project.project_id
  end

  validates_with Hmis::Hud::Validators::EnrollmentValidator
  validate :client_is_valid, on: :new_client_enrollment_form

  SORT_OPTIONS = [
    :most_recent,
    :household_id,
    :last_name_a_to_z,
    :last_name_z_to_a,
    :first_name_a_to_z,
    :first_name_z_to_a,
    :age_youngest_to_oldest,
    :age_oldest_to_youngest,
  ].freeze

  SORT_OPTION_DESCRIPTIONS = {
    most_recent: 'Most Recent',
    household_id: 'Household ID',
    last_name_a_to_z: 'Last Name: A-Z',
    last_name_z_to_a: 'Last Name: Z-A',
    first_name_a_to_z: 'First Name: A-Z',
    first_name_z_to_a: 'First Name: Z-A',
    age_youngest_to_oldest: 'Age: Youngest to Oldest',
    age_oldest_to_youngest: 'Age: Oldest to Youngest',
  }.freeze

  # Enrollments at Projects where the user has the specified permission(s).
  # WARNING UNSAFE! This does not check for can_view_project or can_view_enrollment_details.
  # This scope should almost always be used in conjunction with viewable_by.
  scope :with_access, ->(user, *permissions, **kwargs) do
    return none unless user.permissions?(*permissions)

    project_ids = Hmis::Hud::Project.with_access(user, *permissions, **kwargs).order(:id).pluck(:id)
    where(project_pk: project_ids)
  end

  # Enrollments that this user has access to. By default, only returns enrollments that the user has full
  # access to (can_view_enrollment_details).
  #
  # Note: use "replace_scope" hide previous declaration of :viewable_by
  replace_scope :viewable_by, ->(user, include_limited_access_enrollments: false) do
    return with_access(user, :can_view_enrollment_details, :can_view_project, mode: 'all') unless include_limited_access_enrollments
    return none unless user.permissions?(:can_view_enrollment_details, :can_view_limited_enrollment_details, mode: 'any')

    # Projects where the user has full enrollment access
    full_access_project_ids = Hmis::Hud::Project.with_access(user, :can_view_enrollment_details, :can_view_project, mode: 'all').pluck(:id)
    # Projects where the user has limited enrollment access
    limited_access_project_ids = Hmis::Hud::Project.with_access(user, :can_view_limited_enrollment_details).pluck(:id)

    where(project_pk: (full_access_project_ids + limited_access_project_ids).uniq.sort)
  end

  # Free-text search for Enrollment
  scope :matching_search_term, ->(search_term) do
    search_term.strip!

    alpha_numeric = /[[[:alnum:]]-]+/.match(search_term).try(:[], 0) == search_term
    numeric = /[\d-]+/.match(search_term).try(:[], 0) == search_term

    # If numeric, check if it's an Enrollment primary key
    if numeric
      matching_enrollments = where(id: search_term)
      return matching_enrollments if matching_enrollments.exists?
    end

    # If alphanumeric, check if it's an EnrollmentID
    if alpha_numeric
      matching_enrollments = where(enrollment_id: search_term)
      return matching_enrollments if matching_enrollments.exists?
    end

    # If alphanumeric, check if it's a Household ID
    if alpha_numeric
      household_matches = where(e_t[:household_id].lower.matches("#{search_term.downcase}%")) if search_term.size == Hmis::Hud::Household::TRIMMED_HOUSEHOLD_ID_LENGTH
      household_matches = where(e_t[:household_id].lower.eq(search_term.downcase)) unless household_matches&.exists?
      return household_matches if household_matches&.exists?
    end

    # Search by client
    joins(:client).merge(Hmis::Hud::Client.matching_search_term(search_term))
  end

  scope :heads_of_households, -> do
    where(RelationshipToHoH: 1)
  end

  scope :in_progress, -> { where(project_id: nil) }

  scope :not_in_progress, -> { where.not(project_id: nil) }

  scope :with_project_type, ->(project_types) do
    project_pks = Hmis::Hud::Project.where(project_type: project_types).pluck(:id)
    where(project_pk: project_pks)
  end

  scope :with_project, ->(project_pks) do
    where(project_pk: project_pks)
  end

  scope :in_age_group, ->(start_age: 0, end_age: nil) do
    joins(:client).merge(Hmis::Hud::Client.age_group(start_age: start_age, end_age: end_age))
  end

  scope :exited, -> { left_outer_joins(:exit).where(ex_t[:ExitDate].not_eq(nil)) }
  scope :open_including_wip, -> { left_outer_joins(:exit).where(ex_t[:ExitDate].eq(nil)) }
  scope :open_excluding_wip, -> { left_outer_joins(:exit).where(ex_t[:ExitDate].eq(nil)).not_in_progress }
  scope :incomplete, -> { in_progress }

  scope :bed_night_on_date, ->(date) do
    joins(:bed_nights).where(s_t[:date_provided].eq(date))
  end

  # @param project [Project]
  # @param range [DateRange]
  # enrollments that conflict with an entry/exit date
  # * entry date on exit date is allowed
  # * multiple entry dates on same day are not allowed
  scope :with_conflicting_dates, ->(project:, range:) do
    entry_date = range.begin
    raise unless entry_date

    scope = with_project([project.id])
    exit_date = range.end # maybe nil if endless range
    if exit_date
      scope.left_outer_joins(:exit).
        where(
          e_t[:entry_date].eq(entry_date).
          or(
            e_t[:entry_date].lt(exit_date). # enrollments started before exit date
            and(
              ex_t[:exit_date].gt(entry_date).or(ex_t[:exit_date].eq(nil)),
            ), # enrollments with an exit date after the entry date
          ),
        )
    else
      scope.left_outer_joins(:exit).
        where(
          ex_t[:exit_date].eq(nil). # we already have an open enrollment
          or(ex_t[:exit_date].gt(entry_date)).
          or(e_t[:entry_date].gteq(entry_date)),
        )
    end
  end

  after_create :warehouse_trigger_processing
  after_update :warehouse_trigger_processing

  def self.sort_by_option(option)
    raise NotImplementedError unless SORT_OPTIONS.include?(option)

    case option
    when :most_recent
      left_outer_joins(:exit).order(
        e_t[:ProjectID].eq(nil).desc, # work-in-progress enrollments
        ex_t[:ExitDate].eq(nil).desc, # active enrollments
        EntryDate: :desc,
        date_created: :desc,
      )
    when :household_id
      order(household_id: :asc, date_created: :desc)
    when :last_name_a_to_z
      joins(:client).order(c_t[:last_name].asc.nulls_last)
    when :last_name_z_to_a
      joins(:client).order(c_t[:last_name].desc.nulls_last)
    when :first_name_a_to_z
      joins(:client).order(c_t[:first_name].asc.nulls_last)
    when :first_name_z_to_a
      joins(:client).order(c_t[:first_name].desc.nulls_last)
    when :age_youngest_to_oldest
      joins(:client).order(c_t[:dob].desc.nulls_last)
    when :age_oldest_to_youngest
      joins(:client).order(c_t[:dob].asc.nulls_last)
    else
      raise NotImplementedError
    end
  end

  def self.apply_filters(input)
    Hmis::Filter::EnrollmentFilter.new(input).filter_scope(self)
  end

  def self.generate_household_id
    generate_uuid
  end

  def self.generate_enrollment_id
    generate_uuid
  end

  def save_new_enrollment!
    raise 'Unexpected: save_new_enrollment called on a persisted enrollment' if persisted?

    if Hmis::ProjectAutoEnterConfig.detect_best_config_for_project(project)
      # If auto-enter is configured for this project, save as non-WIP and generate an empty intake.
      save_not_in_progress!
      build_synthetic_intake_assessment.save!
    else
      # Otherwise, save as WIP
      save_in_progress!
    end
  end

  def save_in_progress!
    raise 'cannot unset ProjectID on enrollment that is missing project_pk' unless project_pk

    # "WIP" Enrollments have a null ProjectID column, so that they aren't included in reporting.
    self.project_id = nil
    save!(validate: false)
  end
  alias save_in_progress save_in_progress!

  def save_not_in_progress!
    self.project_id = project.project_id
    save!
  end
  alias save_not_in_progress save_not_in_progress!

  def in_progress?
    self.ProjectID.nil?
  end

  def exit_in_progress?
    exit.nil? && exit_assessment&.present?
  end

  def head_of_household?
    self.RelationshipToHoH == 1
  end

  def adult?
    client.adult?
  end

  def household_members
    Hmis::Hud::Enrollment.where(household_id: household_id, data_source_id: data_source_id)
  end

  def hoh_entry_date
    household_members.heads_of_households.first&.entry_date
  end

  # track change via attr to avoid adding complexity to form processor
  attr_accessor :unit_occupancy_changes
  after_save :track_unit_occupancy_changes, if: :unit_occupancy_changes
  def track_unit_occupancy_changes
    unit_type, user_id, project_id = unit_occupancy_changes.fetch_values(:unit_type, :user_id, :project_id)
    unit_type.track_availability(project_id: project_id, user_id: user_id)
  end

  def assign_unit(unit:, start_date:, user:)
    current_occupancy = active_unit_occupancy.present? if active_unit_occupancy&.occupancy_period&.active?
    # ignore: this enrollment is already assigned to this unit
    return if current_occupancy.present? && current_occupancy.unit == unit

    # error: this enrollment is already assigned to a different unit
    raise 'Enrollment is already assigned to a different unit' if current_occupancy.present?

    # error: the unit is occupied by someone who is NOT in this household
    occupants = unit.occupants_on(start_date)
    raise 'Unit is already assigned to a different household' if occupants.where.not(household_id: household_id).present?

    # include project id here since it may not be available during after_save hooks due to WIP
    self.unit_occupancy_changes = { project_id: unit.project_id, unit_type: unit.unit_type, user_id: user.id } if unit.unit_type
    unit_occupancies.build(
      unit: unit,
      occupancy_period_attributes: {
        start_date: start_date,
        end_date: nil,
        user: user,
      },
    )
  end

  def release_unit!(occupancy_end_date = Date.current, user:)
    occupancy = active_unit_occupancy
    # If enrollment isn't assigned to any unit, do nothing
    return if occupancy.nil? || occupancy.occupancy_period.nil?

    transaction do
      occupancy.occupancy_period.update!(end_date: occupancy_end_date, user: user)
      unit_type = occupancy.unit&.unit_type
      unit_type&.track_availability(project_id: project.id, user_id: user.id)
    end
  end

  def unit_occupied_on(date = Date.current)
    Hmis::UnitOccupancy.active(date).where(enrollment: self).first&.unit
  end

  def build_synthetic_intake_assessment
    assessment = Hmis::Hud::CustomAssessment.new(
      CustomAssessmentID: Hmis::Hud::Base.generate_uuid,
      enrollment_id: enrollment_id,
      personal_id: personal_id,
      assessment_date: entry_date,
      user_id: user_id || Hmis::Hud::User.system_user(data_source_id: data_source_id)&.user_id,
      data_source_id: data_source_id,
      data_collection_stage: 1, # Intake
      wip: false,
    )
    # Build a FormProcessor. It has no references since no records are created. It is not necessary
    # to link a Form Definition, because a Form Definition will be selected when/if the form is opened for editing.
    assessment.build_form_processor
    assessment
  end

  # When submitting a new_client_enrollment form, we validate the client too, with the same validation contexts
  private def client_is_valid
    return unless client.present?

    client.valid?([:form_submission, :new_client_enrollment_form])
    errors.merge!(client.errors)
  end

  private def warehouse_trigger_processing
    return unless warehouse_columns_changed?

    invalidate_processing!
    queue_service_history_processing!
  end

  private def warehouse_columns_changed?
    (saved_changes.keys & ['EntryDate', 'ProjectID', 'DateDeleted']).any?
  end

  include RailsDrivers::Extensions
end
