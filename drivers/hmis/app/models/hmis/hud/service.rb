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

  belongs_to :enrollment, **hmis_relation(:EnrollmentID, 'Enrollment')
  belongs_to :client, **hmis_relation(:PersonalID, 'Client')
  belongs_to :user, **hmis_relation(:UserID, 'User'), inverse_of: :services
  belongs_to :data_source, class_name: 'GrdaWarehouse::DataSource'
  has_one :project, through: :enrollment

  validates_with Hmis::Hud::Validators::ServiceValidator
end
