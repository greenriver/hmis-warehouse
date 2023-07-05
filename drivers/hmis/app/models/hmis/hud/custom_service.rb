###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class Hmis::Hud::CustomService < Hmis::Hud::Base
  self.table_name = :CustomServices
  self.sequence_name = "public.\"#{table_name}_id_seq\""
  include ::HmisStructure::Service
  include ::Hmis::Hud::Concerns::Shared
  include ::Hmis::Hud::Concerns::EnrollmentRelated
  include ::Hmis::Hud::Concerns::ClientProjectEnrollmentRelated

  belongs_to :enrollment, **hmis_relation(:EnrollmentID, 'Enrollment')
  belongs_to :client, **hmis_relation(:PersonalID, 'Client')
  belongs_to :user, **hmis_relation(:UserID, 'User'), inverse_of: :services
  belongs_to :data_source, class_name: 'GrdaWarehouse::DataSource'
  belongs_to :custom_service_type
  alias_attribute :service_type, :custom_service_type
  has_many :custom_data_elements, as: :owner
  has_one :organization, through: :project

  accepts_nested_attributes_for :custom_data_elements, allow_destroy: true
  alias_to_underscore [:FAAmount, :FAStartDate, :FAEndDate]
  before_validation :set_service_name
  validates_with Hmis::Hud::Validators::CustomServiceValidator

  def self.hud_key
    'CustomServiceID'
  end

  private def set_service_name
    return if service_name.present?

    assign_attributes(service_name: service_type.name)
  end
end
