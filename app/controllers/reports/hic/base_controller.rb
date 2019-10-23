###
# Copyright 2016 - 2019 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module Reports
  class Hic::BaseController < ApplicationController
    before_action :require_can_view_all_reports!
    # ES (1), TH (2), SH (8), PSH (3), RRH (13), PH (10), PH (9)
    PROJECT_TYPES = [1, 2, 3, 8, 9, 10, 13].freeze
  end
end
