###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module ClientAccessControl::GrdaWarehouse
  module ServiceHistoryEnrollmentExtension
    extend ActiveSupport::Concern

    included do
      has_many :hmis_organizations, through: :group_viewable_entities, source: :entity, source_type: 'Hmis::Hud::Organization'
      has_many :hmis_projects, through: :group_viewable_entities, source: :entity, source_type: 'Hmis::Hud::Project'
    end
  end
end
