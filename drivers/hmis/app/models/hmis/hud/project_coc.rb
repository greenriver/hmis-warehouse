###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class Hmis::Hud::ProjectCoc < Hmis::Hud::Base
  self.table_name = :ProjectCoC
  self.sequence_name = "public.\"#{table_name}_id_seq\""
  include ::HmisStructure::ProjectCoc
  include ::Hmis::Hud::Concerns::Shared
  include ::Hmis::Hud::Concerns::ProjectRelated
  validates_with Hmis::Hud::Validators::ProjectCocValidator

  belongs_to :data_source, class_name: 'GrdaWarehouse::DataSource'
  belongs_to :project, **hmis_relation(:ProjectID, 'Project')
  belongs_to :user, **hmis_relation(:UserID, 'User'), optional: true

  def required_fields
    @required_fields ||= [
      :ProjectID,
      :CoCCode,
      :Geocode,
    ]
  end
end
