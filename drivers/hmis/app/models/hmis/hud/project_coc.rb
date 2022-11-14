###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class Hmis::Hud::ProjectCoc < Hmis::Hud::Base
  include ::HmisStructure::ProjectCoc
  include ::Hmis::Hud::Shared
  self.table_name = :ProjectCoC
  self.sequence_name = "public.\"#{table_name}_id_seq\""
  validates_with Hmis::Hud::Validators::ProjectCocValidator

  belongs_to :project, **hmis_relation(:ProjectID, 'Project')

  scope :viewable_by, ->(user) do
    joins(:project).merge(Hmis::Hud::Project.viewable_by(user))
  end

  scope :editable_by, ->(user) do
    joins(:project).merge(Hmis::Hud::Project.editable_by(user))
  end

  def required_fields
    @required_fields ||= [
      :ProjectID,
      :CoCCode,
      :Geocode,
    ]
  end
end
