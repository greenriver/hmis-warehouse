###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HudPathReport
  class PathsController < BaseController
    before_action :generator, only: [:download]
    before_action :set_report, only: [:show, :destroy, :running, :download, :restore]
    before_action :set_reports, except: [:index, :running_all_questions]
    before_action :set_pdf_export, only: [:show, :download]
  end
end
