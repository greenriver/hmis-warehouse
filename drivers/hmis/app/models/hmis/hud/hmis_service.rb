###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class Hmis::Hud::HmisService < Hmis::Hud::Base
  self.table_name = :hmis_services
  self.primary_key = :id

  include ::Hmis::Hud::Concerns::EnrollmentRelated
  include ::Hmis::Hud::Concerns::ClientProjectEnrollmentRelated

  belongs_to :enrollment, **hmis_enrollment_relation, optional: true
  belongs_to :client, **hmis_relation(:PersonalID, 'Client')
  belongs_to :user, **hmis_relation(:UserID, 'User'), inverse_of: :services
  belongs_to :data_source, class_name: 'GrdaWarehouse::DataSource'
  belongs_to :owner, polymorphic: true # Service or CustomService
  belongs_to :custom_service_type
  has_many :custom_service_categories, through: :custom_service_type

  validate :service_is_valid

  alias_attribute :service_type, :custom_service_type
  alias_to_underscore [:DateProvided, :EnrollmentID, :PersonalID]

  after_initialize :initialize_owner, if: :new_record?

  SORT_OPTIONS = [:date_provided].freeze
  HUD_ATTRIBUTES = [:record_type, :type_provided, :other_type_provided, :moving_on_other_type, :sub_type_provided, :referral_outcome].freeze
  HUD_AND_CUSTOM_ATTRIBUTES = [:fa_amount, :fa_start_date, :fa_end_date].freeze

  delegate(*HUD_AND_CUSTOM_ATTRIBUTES, to: :owner)
  attr_accessor(*HUD_ATTRIBUTES)

  HUD_ATTRIBUTES.each do |hud_field_name|
    define_method(hud_field_name) { hud_service&.send(hud_field_name) }
  end

  scope :with_service_type, ->(service_type_id) do
    where(custom_service_type_id: service_type_id)
  end

  scope :in_service_category, ->(category_id) do
    type_ids = Hmis::Hud::CustomServiceType.where(custom_service_category_id: category_id).pluck(:id)
    with_service_type(type_ids)
  end

  scope :with_project_type, ->(project_types) do
    joins(:enrollment).merge(Hmis::Hud::Enrollment.with_project_type(project_types))
  end

  scope :with_project, ->(project_ids) do
    joins(:enrollment).merge(Hmis::Hud::Enrollment.with_project(project_ids))
  end

  scope :matching_search_term, ->(search_term) do
    return none unless search_term.present?

    search_term.strip!
    query = "%#{search_term}%"
    joins(:custom_service_type, :custom_service_categories).
      where(cst_t[:name].matches(query).or(csc_t[:name].matches(query)))
  end

  def self.apply_filters(input)
    Hmis::Filter::ServiceFilter.new(input).filter_scope(self)
  end

  def readonly?
    true
  end

  private def initialize_owner
    raise 'Cannot initialize HmisService without a CustomServiceType' unless custom_service_type.present?

    attrs = [:enrollment_id, :personal_id, :user_id, :data_source_id].map { |k| [k, send(k)] }.to_h
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
      order(DateProvided: :desc)
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
