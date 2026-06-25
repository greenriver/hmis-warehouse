###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Admin
  class AccessOverviewsController < ApplicationController
    include AjaxModalRails::Controller

    before_action :require_can_edit_roles!

    def index
      @modal_size = :xl
    end
  end
end
