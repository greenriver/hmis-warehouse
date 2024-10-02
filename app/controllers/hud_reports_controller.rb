###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class HudReportsController < ApplicationController
  include AjaxModalRails::Controller
  before_action :require_can_view_hud_reports!

  def index
  end
end
