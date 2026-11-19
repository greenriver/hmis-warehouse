###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class PublicLogosController < ApplicationController
  include ControllerThemeLogoBehavior

  skip_before_action :authenticate_user!

  def show
    show_logo
  end
end
