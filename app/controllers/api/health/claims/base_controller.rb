module Api::Health::Claims
  class BaseController < ApplicationController
    before_action :require_can_view_aggregate_health!
    before_action :load_data
    
    def index
      render json: @data
    end

    def load_data
      raise NotImplementedError
    end

    # group the data by date, then sum each column
    def group_by_date_and_sum_by_category(data)
      sums = Hash.new(0)
      data.group_by do |row|
        Date.new(row.year, row.month, 01)
      end.map do |date, data|
        data = data.map do |row|
          row.attributes.with_indifferent_access.
          except(:id, :medicaid_id, :year, :month)
        end.each_with_object(sums) do |row, sums|
            row.each do |k, v|
              sums[k] += v
            end
          end
        {date: date}.merge(data)
      end
    end
  end
end