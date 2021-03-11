###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module ClientAccessControl::GrdaWarehouse
  module ServiceHistoryEnrollmentExtension
    extend ActiveSupport::Concern

    included do
      scope :visible_to, ->(user) do
      end
    end
  end
end
