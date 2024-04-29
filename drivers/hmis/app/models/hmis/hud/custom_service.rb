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
  include ::Hmis::Hud::Concerns::HasCustomDataElements

  belongs_to :enrollment, foreign_key: :enrollment_pk, optional: true, class_name: 'Hmis::Hud::Enrollment'
  has_one :project, through: :enrollment

  belongs_to :client, **hmis_relation(:PersonalID, 'Client')
  belongs_to :user, **hmis_relation(:UserID, 'User'), inverse_of: :services, optional: true
  belongs_to :data_source, class_name: 'GrdaWarehouse::DataSource'
  belongs_to :custom_service_type
  alias_attribute :service_type, :custom_service_type
  has_one :organization, through: :project
  has_one :custom_service_category, through: :custom_service_type
  has_one :warehouse_project, class_name: 'GrdaWarehouse::Hud::Project', through: :project

  before_validation :set_service_name
  validates_with Hmis::Hud::Validators::CustomServiceValidator

  before_validation :set_hud_enrollment_id_from_enrollment_pk, if: :enrollment_pk_changed?
  def set_hud_enrollment_id_from_enrollment_pk
    self.enrollment_id = enrollment.enrollment_id
    self.personal_id = enrollment.personal_id
  end

  def validate_enrollment_pk
    if enrollment
      errors.add :enrollment_id, 'does not match DB PK' if EnrollmentID != enrollment.EnrollmentID
      errors.add :enrollment_id, 'must match enrollment data source' if data_source_id != enrollment.data_source_id
    else
      errors.add :enrollment_pk, :required
    end
  end

  scope :within_range, ->(range) do
    where(date_provided: range)
  end

  def self.hud_key
    'CustomServiceID'
  end

  def within_range?(range)
    date_provided.between?(range.begin, range.end)
  end

  def display_name
    return service_type.name if custom_service_category.name == service_type.name

    "#{custom_service_category.name} - #{service_type.name}"
  end

  private def set_service_name
    return if service_name.present?

    assign_attributes(service_name: service_type.name)
  end
end
