###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudPit
  class PitsController < ::HudReports::BaseController
    include PitConcern
    before_action :filter
    before_action :generator, only: [:download]
    before_action :set_report, only: [:show, :destroy, :running, :download]
    before_action :set_reports, except: [:index, :running_all_questions]
  end
end
