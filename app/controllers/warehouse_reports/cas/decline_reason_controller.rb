module WarehouseReports::Cas
  class DeclineReasonController < ApplicationController
    before_action :require_can_view_reports!

    def index
      date_range_options = params.permit(range: [:start, :end])[:range]
      unless date_range_options.present?
        date_range_options = {
          start: 13.month.ago.to_date,
          end: 1.months.ago.to_date,
        }
      end
      @range = ::Filters::DateRange.new(date_range_options)
      @raw_reasons = GrdaWarehouse::CasReport.where.not( decline_reason: nil ).
        started_between(start_date: @range.start, end_date: @range.end + 1.day)
      @reasons = @raw_reasons.map do|row| 
        row[:decline_reason].squish.gsub(/Other.*/,'Other').strip
      end.each_with_object(Hash.new(0)) { |reason,counts| counts[reason] += 1 }

      @reasons.sort_by(&:last).reverse
      
      respond_to do |format|
        format.html
        format.xlsx
      end
    end
  end
end