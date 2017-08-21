module Census
  class ProjectTypesController < ::ApplicationController
    before_action :require_can_view_censuses!
    include ArelHelper

    def index
      date_range_options = params.permit(range: [:start, :end])[:range]
      if date_range_options.present? && date_range_options[:start].present?
        @range = ::Filters::DateRange.new(date_range_options)
      else
        @range = ::Filters::DateRange.new(start: 3.years.ago.to_date, end: 1.day.ago.to_date)
      end
    end

    def json
      date_range_options = params.permit(:start_date, :end_date)
      @range = ::Filters::DateRange.new(start: date_range_options[:start_date], end: date_range_options[:end_date])
      @census = Censuses::CensusByProjectType.new()
      scope = homeless_scope
      scope = scope.veteran if params[:veteran].present?
      @data = @census.for_date_range_combined(
        start_date: @range.start, 
        end_date: @range.end,
        scope: scope
      )
      @data[:title] = {text: 'Daily Census by Project Type'}
      render json: {all: @data}
    end

    def homeless_scope
      GrdaWarehouse::CensusByProjectType.homeless
    end
  end
end