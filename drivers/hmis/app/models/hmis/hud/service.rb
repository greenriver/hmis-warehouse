###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class Hmis::Hud::Service < Hmis::Hud::Base
  self.table_name = :Services
  self.sequence_name = "public.\"#{table_name}_id_seq\""
  include ::HmisStructure::Service
  include ::Hmis::Hud::Concerns::Shared
  include ::Hmis::Hud::Concerns::EnrollmentRelated
  include ::Hmis::Hud::Concerns::ClientProjectEnrollmentRelated

  belongs_to :enrollment, **hmis_enrollment_relation, optional: true
  belongs_to :client, **hmis_relation(:PersonalID, 'Client')
  belongs_to :user, **hmis_relation(:UserID, 'User'), inverse_of: :services
  belongs_to :data_source, class_name: 'GrdaWarehouse::DataSource'
  has_many :custom_data_elements, as: :owner, dependent: :destroy

  accepts_nested_attributes_for :custom_data_elements, allow_destroy: true
  alias_to_underscore [:FAAmount, :FAStartDate, :FAEndDate]
  validates_with Hmis::Hud::Validators::ServiceValidator

  # On user-initiated change, validate that there is max 1 bed night per date
  validates_uniqueness_of :enrollment_id,
                          scope: [:date_provided, :data_source_id],
                          conditions: -> { bed_nights },
                          on: [:form_submission, :bed_nights_mutation]

  scope :bed_nights, -> { where(RecordType: 200) }
end
