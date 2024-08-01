###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module SyntheticCeAssessment::GrdaWarehouse::Hud
  module ProjectExtension
    extend ActiveSupport::Concern

    included do
      has_one :synthetic_ce_project_config, class_name: 'SyntheticCeAssessment::ProjectConfig'
    end
  end
end
