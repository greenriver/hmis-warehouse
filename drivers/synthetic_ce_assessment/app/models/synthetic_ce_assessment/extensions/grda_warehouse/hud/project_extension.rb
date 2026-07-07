###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module SyntheticCeAssessment::GrdaWarehouse::Hud
  module ProjectExtension
    extend ActiveSupport::Concern

    included do
      has_one :synthetic_ce_project_config, class_name: 'SyntheticCeAssessment::ProjectConfig'
    end
  end
end
