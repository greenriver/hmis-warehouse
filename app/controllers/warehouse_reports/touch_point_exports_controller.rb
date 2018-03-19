module WarehouseReports
  class TouchPointExportsController < ApplicationController
    include WarehouseReportAuthorization
    
    def index
      options = {search_scope: touch_point_scope}
      options.merge!(filter_params) if filter_params.present?
      @filter = ::Filters::TouchPointExportsFilter.new(options)
    end

    def download
      @name = filter_params[:name]
      @start_date = filter_params[:start]
      @end_date = filter_params[:end]

      if @name.blank? || @start_date.blank? || @end_date.blank?
        redirect_to warehouse_reports_touch_point_exports_path, notice: 'Please select a name, start and end date' and return
      end

      @responses = report_source.select(:client_id, :answers, :collected_at, :data_source_id, :assessment_id, :site_id). joins(:hmis_assessment, client: :destination_client). where(name: @name). where(collected_at: (@start_date..@end_date)). order(:client_id, :collected_at)
      @data = { sections: {} }
      @sections = {}
      @responses.each do |response|
        answers = response.answers
        client_name = response.client.name
        client_id = response.client.destination_client.id
        date = response.collected_at
        answers[:sections].each do |section|
          title = section[:section_title]
          @sections[title] ||= []
          @data[:sections][title] ||= {}
          section[:questions].each do |question|
            question_text = question[:question]
            @sections[title] |= [question_text]
            @data[:sections][title][question_text] ||= {}
            @data[:sections][title][question_text][client_id] ||= {}
            @data[:sections][title][question_text][client_id][date.to_s] = question[:answer]
          end
        end
      end

      respond_to do |format|
        format.xlsx do
          headers['Content-Disposition'] = "attachment; filename=Touch Point Exports - #{@name} #{@start} to #{@end}.xlsx"
        end
      end
    end

    def filter_params
      params.permit( filter: [:name, :start, :end] )[:filter]
    end

    def report_source
      GrdaWarehouse::HmisForm.non_confidential
    end

    def touch_point_scope
      GrdaWarehouse::HMIS::Assessment.non_confidential
    end

  end
end
