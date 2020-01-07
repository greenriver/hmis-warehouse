###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module WarehouseReports
  class TouchPointExportsController < ApplicationController
    include WarehouseReportAuthorization
    before_action :set_filter_options, only: [:download]
    before_action :load_responses, only: [:download]

    def index
      options = { search_scope: touch_point_scope }
      options.merge!(filter_params) if filter_params.present?
      @filter = ::Filters::TouchPointExportsFilter.new(options)
    end

    def download
      respond_to do |format|
        format.xlsx do
          headers['Content-Disposition'] = "attachment; filename=TouchPoints-#{@name} #{@start_date&.to_date&.strftime('%F')} to #{@end_date&.to_date&.strftime('%F')}.xlsx"
        end
      end
    end

    def set_filter_options
      @name = filter_params[:name]
      @start_date = filter_params[:start]
      @end_date = filter_params[:end]

      return unless @name.blank? || @start_date.blank? || @end_date.blank?

      flash[:notice] = 'Please select a name, start, and end date'
      redirect_to(action: :index)
      nil
    end

    def load_responses
      @responses = report_source.select(:id, :client_id, :answers, :collected_at, :data_source_id, :assessment_id, :site_id, :staff).
        joins(:hmis_assessment, client: :destination_client).
        where(name: @name).
        where(collected_at: (@start_date..@end_date)).
        order(:client_id, :collected_at)
      @data = { sections: {} }
      @sections = {}
      @client_ids = Set.new
      @responses.each do |response|
        answers = response.answers
        # client_name = response.client.name
        client_id = response.client.destination_client.id
        @client_ids << client_id
        # date = response.collected_at
        response_id = response.id
        answers[:sections].each do |section|
          title = section[:section_title]
          @sections[title] ||= []
          @data[:sections][title] ||= {}
          section[:questions].each do |question|
            question_text = question[:question]
            @sections[title] |= [question_text] # Union version of += (add if not there) for array
            @data[:sections][title][question_text] ||= {}
            @data[:sections][title][question_text][client_id] ||= {}
            @data[:sections][title][question_text][client_id][response_id] = question[:answer]
          end
        end
      end
    end

    def filter_params
      params.permit(filter: [:name, :start, :end])[:filter]
    end

    def report_source
      GrdaWarehouse::HmisForm.non_confidential
    end

    def touch_point_scope
      GrdaWarehouse::HMIS::Assessment.non_confidential
    end
  end
end
