###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'memoist'
module GrdaWarehouse::CasProjectClientCalculator
  class Mdha
    def value_for_cas_project_client(client:, column:)
      current_value = client.send(column)
      return current_value unless column.to_sym == :match_group

      # return 1 if has encampment decomissioning flag

      return 2 if client.veteran?

      return 3
    end
  end
end
