###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Hmis::Hud::Processors
  class EnrollmentCocProcessor < Base
    def factory_name
      :enrollment_coc_factory
    end

    def graphql_enum(_)
      nil # No schema, so graphql_enum is always nil
    end
  end
end
