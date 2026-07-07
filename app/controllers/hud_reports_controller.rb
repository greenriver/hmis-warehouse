###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class HudReportsController < ApplicationController
  include AjaxModalRails::Controller
  before_action :require_can_view_hud_reports!

  def index
  end
end
