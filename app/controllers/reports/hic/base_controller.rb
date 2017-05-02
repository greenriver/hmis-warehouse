module Reports
  class Hic::BaseController < ApplicationController
    before_action :require_can_view_reports!
    # ES (1), TH (2), SH (8), PSH (3), RRH (13), PH (10), PH (9)
    PROJECT_TYPES = [1, 2, 3, 8, 9, 10, 13]

  end
end