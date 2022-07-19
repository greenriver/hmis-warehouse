###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class Hmis::Hud::Project < Hmis::Hud::Base
  include ::HmisStructure::Project
  include ::Hmis::Hud::Shared
  self.table_name = :Project
  self.sequence_name = "public.\"#{table_name}_id_seq\""

  belongs_to :organization, **hmis_relation(:OrganizationID, 'Organization')

  # Any projects the user has been assigned, limited to the data source the HMIS is connected to
  scope :viewable_by, ->(user) do
    viewable_ids = GrdaWarehouse::Hud::Project.viewable_by_entity(user).pluck(:id)
    where(id: viewable_ids, data_source_id: user.hmis_data_source_id)
  end

  # Always use ProjectType, we shouldn't need overrides since we can change the source data
  scope :with_project_type, ->(project_types) do
    where(ProjectType: project_types)
  end
end
