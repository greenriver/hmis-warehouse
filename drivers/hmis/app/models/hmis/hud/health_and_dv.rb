###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class Hmis::Hud::HealthAndDv < Hmis::Hud::Base
  self.table_name = :HealthAndDV
  self.sequence_name = "public.\"#{table_name}_id_seq\""
  include ::HmisStructure::HealthAndDv
  include ::Hmis::Hud::Concerns::Shared
  include ::Hmis::Hud::Concerns::EnrollmentRelated
  include ::Hmis::Hud::Concerns::ClientProjectEnrollmentRelated

  belongs_to :client, **hmis_relation(:PersonalID, 'Client')
  belongs_to :user, **hmis_relation(:UserID, 'User'), optional: true
  belongs_to :data_source, class_name: 'GrdaWarehouse::DataSource'
end
