###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# Public controller for viewing content pages (e.g. Terms of Service, Privacy Policy).
# These pages can be viewed without authentication for reference purposes.
class ContentPagesController < ApplicationController
  skip_before_action :authenticate_user!
  skip_before_action :require_compliance_agreement!, raise: false

  def show
    @page = GrdaWarehouse::ContentPage.find_by!(slug: params[:slug])
  end
end
