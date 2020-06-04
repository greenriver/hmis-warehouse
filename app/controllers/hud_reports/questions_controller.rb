###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module HudReports
  class QuestionsController < ApplicationController
    before_action :set_generator

    def show
      @question = params[:id]
      @report = @generator.find_report(current_user)
    end

    def set_generator
      generator_id = params[:id].to_i
      @generator = generators[generator_id]
    end

    def generators
      [
        ReportGenerators::Apr::Fy2020::Generator,
      ]
    end
  end
end
