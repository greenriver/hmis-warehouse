###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Theme
  # Exposes theme logos to the IdP login screens. Currently just serves the same logo
  # as PublicLogosController regardless of the requested type; kept as its own controller
  # so we can later serve a distinct logo for the warehouse vs. HMIS IdP without touching
  # the public-facing route.
  class LogoController < ApplicationController
    include ControllerThemeLogoBehavior

    skip_before_action :authenticate_user!

    def show
      show_logo
    end
  end
end
