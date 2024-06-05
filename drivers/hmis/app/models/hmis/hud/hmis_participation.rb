###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class Hmis::Hud::HmisParticipation < Hmis::Hud::Base
  self.table_name = :HMISParticipation
  self.sequence_name = "public.\"#{table_name}_id_seq\""
  include ::HmisStructure::HmisParticipation
  include ::Hmis::Hud::Concerns::Shared
  include ::Hmis::Hud::Concerns::ProjectRelated
  include ::Hmis::Hud::Concerns::FormSubmittable

  belongs_to :project, **hmis_relation(:ProjectID, 'Project')
  belongs_to :data_source, class_name: 'GrdaWarehouse::DataSource'
  belongs_to :user, **hmis_relation(:UserID, 'User'), optional: true, inverse_of: :projects
end
