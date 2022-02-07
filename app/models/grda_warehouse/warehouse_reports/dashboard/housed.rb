###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module GrdaWarehouse::WarehouseReports::Dashboard
  class Housed < GrdaWarehouse::WarehouseReports::Dashboard::Base

    def self.params
      {
        start_date: '2014-07-01'.to_date
      }
    end

    def run!
      @start_date = parameters.with_indifferent_access[:start_date].to_date
      @end_date = 1.month.ago.end_of_month.to_date
      columns = [:date, :destination, :client_id]
      all_exits = exits_from_homelessness.
        ended_between(start_date: @start_date, end_date: @end_date + 1.day).
        order(date: :asc).
        pluck(*columns).map do |date, destination, client_id|
          destination = 99 unless ::HUD.valid_destinations.keys.include?(destination)
          Hash[columns.zip([date, destination, client_id])]
        end


      all_destinations = all_exits.map{|m| m[:destination]}.uniq
      all_date_buckets = (@start_date...@end_date).map{|date| date.strftime('%b %Y')}.uniq;
      all_date_buckets = all_date_buckets.zip(Array.new(all_date_buckets.size, 0)).to_h

      @ph_clients = all_exits.select{|m| ::HUD.permanent_destinations.include?(m[:destination])}.map{|m| m[:client_id]}.uniq

      @buckets = {}

      all_destinations.each do |destination|
        label = ::HUD::destination(destination).to_s
        if label.is_a? Numeric
          label = ::HUD::destination(99)
        end
        @buckets[destination] ||= {
          source_data: all_date_buckets.deep_dup,
          label: label.truncate(45),
          backgroundColor: colorize(label),
          ph: ::HUD.permanent_destinations.include?(destination),
        }
      end

      # Count up all of the exits into buckets
      all_exits.each do |row|
        destination = row[:destination]
        date = row[:date].to_date
        @buckets[destination][:source_data][date.strftime('%b %Y')] ||= 0
        @buckets[destination][:source_data][date.strftime('%b %Y')] += 1
      end

      @all_exits_labels = @buckets&.values&.first.try(:[], :source_data)&.keys
      @ph_exits = @buckets.deep_dup.select{|_,m| m[:ph]}

      # Add some chart.js friendly counts
      @ph_exits.each do |destination, group|
        @ph_exits[destination][:data] = group[:source_data].values
      end
      @buckets.each do |destination, group|
        @buckets[destination][:data] = group[:source_data].values
      end
      data = {
        ph_clients: @ph_clients,
        buckets: @buckets,
        ph_exits: @ph_exits,
        all_exits_labels: @all_exits_labels,
        start_date: @start_date,
        end_date: @end_date,
      }
    end


  end
end
