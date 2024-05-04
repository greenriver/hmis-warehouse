###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# backed by database view
class Hmis::Hud::HmisService < Hmis::Hud::Base
  self.table_name = :hmis_services
  self.primary_key = :id

  replace_scope :viewable_by, ->(user) do
    joins(:enrollment).merge(Hmis::Hud::Enrollment.viewable_by(user))
  end
  include ::Hmis::Hud::Concerns::ClientProjectEnrollmentRelated

  belongs_to :client, **hmis_relation(:PersonalID, 'Client')
  belongs_to :user, **hmis_relation(:UserID, 'User'), optional: true, inverse_of: :services
  belongs_to :data_source, class_name: 'GrdaWarehouse::DataSource'
  belongs_to :owner, polymorphic: true # Service or CustomService

  validate :service_is_valid

  alias_to_underscore [:DateProvided, :EnrollmentID, :PersonalID]

  after_initialize :initialize_owner, if: :new_record?

  SORT_OPTIONS = [
    :date_provided,
    :last_name_a_to_z,
    :last_name_z_to_a,
    :first_name_a_to_z,
    :first_name_z_to_a,
    :age_youngest_to_oldest,
    :age_oldest_to_youngest,
  ].freeze

  SORT_OPTION_DESCRIPTIONS = {
    date_provided: 'Date service was provided',
    last_name_a_to_z: 'Client Last Name: A-Z',
    last_name_z_to_a: 'Client Last Name: Z-A',
    first_name_a_to_z: 'Client First Name: A-Z',
    first_name_z_to_a: 'Client First Name: Z-A',
    age_youngest_to_oldest: 'Client Age: Youngest to Oldest',
    age_oldest_to_youngest: 'Client Age: Oldest to Youngest',
  }.freeze

  HUD_ATTRIBUTES = [:record_type, :type_provided, :other_type_provided, :moving_on_other_type, :sub_type_provided, :referral_outcome].freeze
  HUD_AND_CUSTOM_ATTRIBUTES = [:fa_amount, :fa_start_date, :fa_end_date].freeze

  delegate(*HUD_AND_CUSTOM_ATTRIBUTES, to: :owner)
  attr_accessor(*HUD_ATTRIBUTES)

  HUD_ATTRIBUTES.each do |hud_field_name|
    define_method(hud_field_name) { hud_service&.send(hud_field_name) }
  end

  scope :with_service_type, ->(csts) do
    conds = csts.map do |cst|
      if cst.hud_service?
        # the arel is hard to parse, but this is just:
        # custom_service_type_id = ? OR ("RecordType" = ? AND "TypeProvided" = ?)
        arel_table[:custom_service_type_id].eq(cst.id).
          or(
            arel_table[:RecordType].eq(cst.hud_record_type).
              or(arel_table[:TypeProvided].eq(cst.hud_type_provided)),
          )
      else
        arel_table[:custom_service_type_id].eq(cst.id)
      end
    end
    return where(conds.reduce(&:or)) if conds.any?

    return none
  end

  scope :with_project_type, ->(project_types) do
    joins(:enrollment).merge(Hmis::Hud::Enrollment.with_project_type(project_types))
  end

  scope :with_project, ->(project_ids) do
    joins(:enrollment).merge(Hmis::Hud::Enrollment.with_project(project_ids))
  end

  def self.apply_filters(input)
    Hmis::Filter::ServiceFilter.new(input).filter_scope(self)
  end

  def readonly?
    true
  end

  private def initialize_owner
    raise 'Cannot initialize HmisService without a CustomServiceType' unless custom_service_type.present?

    attrs = [:enrollment_id, :personal_id, :user_id, :data_source_id, :date_provided].map { |k| [k, send(k)] }.to_h
    if custom_service_type.hud_service?
      self.owner = Hmis::Hud::Service.new(**attrs)
    else
      self.owner = Hmis::Hud::CustomService.new(**attrs, custom_service_type: custom_service_type)
    end
  end

  HUD_SERVICE_ID_PREFIX = '1'.freeze
  CUSTOM_SERVICE_ID_PREFIX = '2'.freeze

  # HmisService IDs are prefixed. Check if a given ID format is valid.
  def self.valid_id?(id)
    return false unless id.to_s.length > 1

    [HUD_SERVICE_ID_PREFIX, CUSTOM_SERVICE_ID_PREFIX].include?(id.to_s.first)
  end

  def hud_service?
    owner.is_a? Hmis::Hud::Service
  end

  def custom_service?
    owner.is_a? Hmis::Hud::CustomService
  end

  private def hud_service
    owner if hud_service?
  end

  private def custom_service
    owner if custom_service?
  end

  def self.sort_by_option(option)
    raise NotImplementedError unless SORT_OPTIONS.include?(option)

    case option
    when :date_provided
      order(DateProvided: :desc, id: :desc)
    when :last_name_a_to_z
      joins(enrollment: :client).order(c_t[:LastName].asc.nulls_last, id: :desc)
    when :last_name_z_to_a
      joins(enrollment: :client).order(c_t[:LastName].desc.nulls_last, id: :desc)
    when :first_name_a_to_z
      joins(enrollment: :client).order(c_t[:FirstName].asc.nulls_last, id: :desc)
    when :first_name_z_to_a
      joins(enrollment: :client).order(c_t[:FirstName].desc.nulls_last, id: :desc)
    when :age_youngest_to_oldest
      joins(enrollment: :client).order(c_t[:dob].asc.nulls_last, id: :desc)
    when :age_oldest_to_youngest
      joins(enrollment: :client).order(c_t[:dob].desc.nulls_last, id: :desc)
    else
      raise NotImplementedError
    end
  end

  # Pull up the errors from the assessment form_processor so we can see them (as opposed to validates_associated)
  private def service_is_valid
    return if owner.valid?

    owner.errors.each do |error|
      errors.add(error.attribute, error.type, **error.options)
    end
  end
end
