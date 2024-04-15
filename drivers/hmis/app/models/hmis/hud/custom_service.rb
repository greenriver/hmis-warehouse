###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# "CustomService" is NOT a HUD defined record type. Although it uses CamelCase conventions, this model is particular to Open Path. CamelCase is used for compatibility with "Appendix C - Custom file transfer template"in the HUD HMIS CSV spec. This specifies optional additional CSV files with the naming convention of Custom*.csv

class Hmis::Hud::CustomService < Hmis::Hud::Base
  self.table_name = :CustomServices
  self.sequence_name = "public.\"#{table_name}_id_seq\""
  include ::HmisStructure::Service
  include ::Hmis::Hud::Concerns::Shared
  include ::Hmis::Hud::Concerns::EnrollmentRelated
  include ::Hmis::Hud::Concerns::ClientProjectEnrollmentRelated
  include ::Hmis::Hud::Concerns::HasCustomDataElements

  belongs_to :client, **hmis_relation(:PersonalID, 'Client')
  belongs_to :user, **hmis_relation(:UserID, 'User'), inverse_of: :services, optional: true
  belongs_to :data_source, class_name: 'GrdaWarehouse::DataSource'
  belongs_to :custom_service_type
  alias_attribute :service_type, :custom_service_type
  has_one :organization, through: :project

  before_validation :set_service_name
  validates_with Hmis::Hud::Validators::CustomServiceValidator

  scope :within_range, ->(range) do
    where(date_provided: range)
  end

  def self.hud_key
    'CustomServiceID'
  end

  def within_range?(range)
    date_provided.between?(range.begin, range.end)
  end

  private def set_service_name
    return if service_name.present?

    assign_attributes(service_name: service_type.name)
  end
end
