###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudApr
  class DqsController < BaseController
    include Dq::DqConcern
    before_action :generator, only: [:download]
    before_action :set_report, only: [:show, :destroy, :running, :download]
    before_action :set_reports, except: [:index, :running_all_questions]
    before_action :set_pdf_export, only: [:show, :download]

    def history
      report_version = params[:filter]&.try(:[], :report_version)

      # FIXME: When there is a 2026 DQ, we will need to check if we want this or the prior controller
      redirect_to history_hud_reports_past_dqs_path(params.permit!) and return if report_version.present?

      # Fall through to the normal history logic
      super
    end

    def available_report_versions
      {
        'FY 2020' => { slug: :fy2020, active: false },
        'FY 2022' => { slug: :fy2022, active: false },
        'FY 2024 (current)' => { slug: :fy2024, active: true },
      }.freeze
    end
  end
end
