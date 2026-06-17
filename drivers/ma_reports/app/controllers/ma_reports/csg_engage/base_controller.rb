###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module MaReports::CsgEngage
  class BaseController < ApplicationController
    before_action :require_can_view_imports!

    def index
    end
  end
end
