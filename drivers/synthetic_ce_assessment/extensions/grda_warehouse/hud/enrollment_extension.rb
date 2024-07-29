###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module SyntheticCeAssessment::GrdaWarehouse::Hud
  module EnrollmentExtension
    extend ActiveSupport::Concern

    included do
      alias_attribute :created_at, :DateCreated
      alias_attribute :updated_at, :DateUpdated
    end
  end
end
