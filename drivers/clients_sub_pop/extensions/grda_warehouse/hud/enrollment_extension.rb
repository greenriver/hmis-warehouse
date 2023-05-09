###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module ClientsSubPop::GrdaWarehouse::Hud
  module EnrollmentExtension
    extend ActiveSupport::Concern

    included do
      scope :clients, -> do
        current_scope
      end

      scope :all_clients, -> do
        current_scope
      end
    end
  end
end
