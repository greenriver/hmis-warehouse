###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module GrdaWarehouse
  module Shape
    module StateScopes
      extend ActiveSupport::Concern
      included do
        scope :my_state, -> { where(statefp: my_fips_state_code) }
        scope :not_my_state, -> { where.not(statefp: my_fips_state_code) }
      end
    end
  end
end
