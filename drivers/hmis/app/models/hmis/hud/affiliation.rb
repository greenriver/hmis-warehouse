# frozen_string_literal: true

###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class Hmis::Hud::Affiliation < Hmis::Hud::Base
  self.table_name = :Affiliation
  self.sequence_name = "public.\"#{table_name}_id_seq\""

  include ::HmisStructure::Affiliation
  include ::Hmis::Hud::Concerns::Shared

  has_paper_trail(meta: { project_id: ->(r) { r.project&.id } })

  belongs_to :data_source, class_name: 'GrdaWarehouse::DataSource'
  belongs_to :project, **hmis_relation(:ProjectID, 'Project'), inverse_of: :affiliations, optional: true
  # NOTE: you can't use hmis_relation for residential project, the keys don't match
  belongs_to :residential_project, class_name: 'Hmis::Hud::Project', primary_key: [:ProjectID, :data_source_id], query_constraints: [:ResProjectID, :data_source_id], inverse_of: :affiliations, optional: true
  belongs_to :user, **hmis_relation(:UserID, 'User'), inverse_of: :affiliations, optional: true
end
