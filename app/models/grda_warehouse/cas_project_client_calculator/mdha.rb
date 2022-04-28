###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'memoist'
module GrdaWarehouse::CasProjectClientCalculator
  class Mdha
    def value_for_cas_project_client(client:, column:)
      if column.to_sym == :match_group
        match_group(client)
      else
        client.send(column)
      end
    end

    private def match_group(client)
      # TODO: return 1 if client has encampment decomissioning flag, once we have that data
      if client.veteran?
        2
      else
        3
      end
    end
  end
end
