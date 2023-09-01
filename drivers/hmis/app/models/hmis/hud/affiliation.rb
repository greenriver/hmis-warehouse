###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class Hmis::Hud::Affiliation < Hmis::Hud::Base
  include ::HmisStructure::Affiliation
  include ::Hmis::Hud::Concerns::Shared
  self.table_name = :Affiliation
  self.sequence_name = "public.\"#{table_name}_id_seq\""

  belongs_to :data_source, class_name: 'GrdaWarehouse::DataSource'
  belongs_to :project, **hmis_relation(:ProjectID, 'Project'), inverse_of: :affiliations, optional: true
  # NOTE: you can't use hmis_relation for residential project, the keys don't match
  belongs_to :residential_project, class_name: 'Hmis::Hud::Project', primary_key: [:ProjectID, :data_source_id], foreign_key: [:ResProjectID, :data_source_id], inverse_of: :affiliations, optional: true
  belongs_to :user, **hmis_relation(:UserID, 'User'), inverse_of: :affiliations, optional: true
end
