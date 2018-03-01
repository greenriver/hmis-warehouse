module WarehouseReports
  class TouchPointExportsController < ApplicationController

    def index
      @filter = ::Filters::TouchPointExportsFilter.new filter_params
    end

    def download
      @name = filter_params[:name]
      @start_date = filter_params[:start]
      @end_date = filter_params[:end]

      if @name.blank? || @start_date.blank? || @end_date.blank?
        redirect_to warehouse_reports_touch_point_exports_path, notice: 'Please select a name, start and end date' and return
      end

      @responses = datasource.select(:client_id, :answers, :created_at)
        .preload(client: :destination_client)
        .where(name: @name)
        .where(arel[:created_at].gteq(@start_date))
        .where(arel[:created_at].lteq(@end_date))
        .order(:client_id, :created_at)

      @data = { sections: {} }
      @sections = {}
      @responses.each do |response|
        answers = response.answers
        client_name = response.client.name
        client_id = response.client.destination_client.id
        date = response.created_at
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

    def datasource
      GrdaWarehouse::HmisForm
    end

    def arel
      datasource.arel_table
    end

  end
end
