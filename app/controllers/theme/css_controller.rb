###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Theme
  class CssController < ApplicationController
    skip_before_action :authenticate_user!

    def show
      expires_in 1.hour, public: true
      render plain: GrdaWarehouse::Theme.idp_theme_css, content_type: 'text/css'
    end
  end
end
