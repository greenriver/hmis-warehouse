###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class Hmis::Hud::ProjectCoc < Hmis::Hud::Base
  include ::HmisStructure::ProjectCoc
  include ::Hmis::Hud::Concerns::Shared
  self.table_name = :ProjectCoC
  self.sequence_name = "public.\"#{table_name}_id_seq\""
  validates_with Hmis::Hud::Validators::ProjectCocValidator

  belongs_to :project, **hmis_relation(:ProjectID, 'Project')
  include ::Hmis::Hud::Concerns::ProjectRelated

  def required_fields
    @required_fields ||= [
      :ProjectID,
      :CoCCode,
      :Geocode,
    ]
  end
end
