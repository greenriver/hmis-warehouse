###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class Hmis::Hud::HmisService < Hmis::Hud::Base
  self.table_name = :hmis_services
  self.primary_key = :id

  include ::Hmis::Hud::Concerns::EnrollmentRelated

  belongs_to :enrollment, **hmis_relation(:EnrollmentID, 'Enrollment')
  belongs_to :client, **hmis_relation(:PersonalID, 'Client')
  belongs_to :user, **hmis_relation(:UserID, 'User'), inverse_of: :services
  belongs_to :data_source, class_name: 'GrdaWarehouse::DataSource'

  belongs_to :owner, polymorphic: true # Service or CustomService
  belongs_to :custom_service_type
  has_many :custom_service_categories, through: :custom_service_type

  alias_attribute :service_type, :custom_service_type
  alias_to_underscore [:DateProvided]

  SORT_OPTIONS = [:date_provided].freeze
  HUD_ATTRIBUTES = [:record_type, :type_provided, :other_type_provided, :moving_on_other_type, :sub_type_provided, :referral_outcome, :FAAmount].freeze

  HUD_ATTRIBUTES.each do |hud_field_name|
    define_method(hud_field_name) { hud_service&.send(hud_field_name) }
  end

  scope :in_service_category, ->(category_id) do
    type_ids = Hmis::Hud::CustomServiceType.where(custom_service_category_id: category_id).pluck(:id)
    where(custom_service_type_id: type_ids)
  end

  scope :matching_search_term, ->(search_term) do
    return none unless search_term.present?

    search_term.strip!
    query = "%#{search_term}%"
    joins(:custom_service_type, :custom_service_categories).
      where(cst_t[:name].matches(query).or(csc_t[:name].matches(query)))
  end

  def readonly?
    true
  end

  private def hud_service
    owner if owner.is_a? Hmis::Hud::Service
  end

  private def custom_service
    owner if owner.is_a? Hmis::Hud::CustomService
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
end
