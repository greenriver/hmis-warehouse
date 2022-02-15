###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class PublicAgenciesController < ApplicationController
  skip_before_action :authenticate_user!
  def index
    @coc_map = GrdaWarehouse::PublicFile.find_by(name: 'client/releases/coc_map')&.content
    @agencies = Agency.publically_available.preload(:consent_limits)
  end
end
