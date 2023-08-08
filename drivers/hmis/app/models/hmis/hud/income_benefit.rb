###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class Hmis::Hud::IncomeBenefit < Hmis::Hud::Base
  self.table_name = :IncomeBenefits
  self.sequence_name = "public.\"#{table_name}_id_seq\""
  include ::HmisStructure::IncomeBenefit
  include ::Hmis::Hud::Concerns::Shared
  include ::Hmis::Hud::Concerns::EnrollmentRelated
  include ::Hmis::Hud::Concerns::ClientProjectEnrollmentRelated

  belongs_to :enrollment, **hmis_relation(:EnrollmentID, 'Enrollment')
  belongs_to :client, **hmis_relation(:PersonalID, 'Client')
  belongs_to :user, **hmis_relation(:UserID, 'User')
  belongs_to :data_source, class_name: 'GrdaWarehouse::DataSource'
  has_many :custom_data_elements, as: :owner, dependent: :destroy

  accepts_nested_attributes_for :custom_data_elements, allow_destroy: true

  validates_with Hmis::Hud::Validators::IncomeBenefitValidator
end
