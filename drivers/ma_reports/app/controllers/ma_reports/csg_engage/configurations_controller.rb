###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module MaReports::CsgEngage
  class ConfigurationsController < ApplicationController
    before_action :require_can_view_imports!

    def index
      @agencies = MaReports::CsgEngage::Agency.all.preload(program_mappings: [:project, :program_reports])
    end
  end
end
