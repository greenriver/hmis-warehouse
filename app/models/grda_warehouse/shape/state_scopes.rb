###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module GrdaWarehouse
  module Shape
    module StateScopes
      extend ActiveSupport::Concern
      included do
        scope :my_states, -> { where(statefp: my_fips_state_codes) }
        scope :not_my_states, -> { where.not(statefp: my_fips_state_codes) }
      end
    end
  end
end
