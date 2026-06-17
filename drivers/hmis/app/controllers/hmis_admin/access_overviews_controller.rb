###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HmisAdmin
  class AccessOverviewsController < ApplicationController
    include AjaxModalRails::Controller
    include EnforceHmisEnabled

    before_action :require_hmis_admin_access!

    def index
      @modal_size = :xl
    end
  end
end
