###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class IdpThemeCssController < ApplicationController
  skip_before_action :authenticate_user!

  def show
    render plain: GrdaWarehouse::Theme.idp_theme_css, content_type: 'text/css'
  end
end
