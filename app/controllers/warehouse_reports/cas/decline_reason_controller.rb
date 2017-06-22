module WarehouseReports::Cas
  class DeclineReasonController < ApplicationController
    before_action :require_can_view_reports!

    def index
      date_range_options = params.permit(range: [:start, :end])[:range]
      unless date_range_options.present?
        date_range_options = {
          start: 1.month.ago,
          end: 13.months.ago,
        }
      end
      @range = DateRange.new(date_range_options)
      @raw_reasons = GrdaWarehouse::CasReport.where.not( decline_reason: nil ).
        started_between(start_date: @range.start, end_date: @range.end)
      @reasons = @raw_reasons.map{|row| row[:decline_reason].gsub(/Other:.*/,'Other').strip}.
        each_with_object(Hash.new(0)) { |reason,counts| counts[reason] += 1 }

      @reasons.sort_by(&:last).reverse
      
      respond_to do |format|
        format.html
        format.xlsx
      end
    end
  end
end