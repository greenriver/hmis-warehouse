###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https:#//github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###
require 'memery'

module SystemPathways
  class Equity
    include ArelHelper
    include Memery
    include SystemPathways::ChartBase

    def chart_data
      node_names.map do |label|
        [label, node_clients(label).group(:ethnicity).count]
      end
    end
  end
end
