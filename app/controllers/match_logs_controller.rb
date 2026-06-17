###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class MatchLogsController < ApplicationController
  before_action :require_can_view_imports!
  def index
    @duplicates = GrdaWarehouse::IdentifyDuplicatesLog.order(started_at: :desc)
    @pagy, @duplicates = pagy(@duplicates)
  end
end
