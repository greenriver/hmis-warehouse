###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class Hmis::Hud::CeParticipation < Hmis::Hud::Base
  self.table_name = :CEParticipation
  self.sequence_name = "public.\"#{table_name}_id_seq\""
  include ::HmisStructure::CeParticipation
  include ::Hmis::Hud::Concerns::Shared
  include ::Hmis::Hud::Concerns::ProjectRelated
  include ::Hmis::Hud::Concerns::HasCustomDataElements

  belongs_to :project, **hmis_relation(:ProjectID, 'Project')
  belongs_to :data_source, class_name: 'GrdaWarehouse::DataSource'
  belongs_to :user, **hmis_relation(:UserID, 'User'), inverse_of: :projects, optional: true
end
