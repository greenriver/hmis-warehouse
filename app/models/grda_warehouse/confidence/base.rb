###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# A base class for specific confidence models

module GrdaWarehouse::Confidence
  class Base < GrdaWarehouseBase
    include NotifierConfig

    self.table_name = :data_monitorings

    scope :processed, -> do
      # use calculated_on which is indexed.
      where.not(value: nil)
    end

    scope :unprocessed, -> do
      where(value: nil)
    end

    scope :queued, -> do
      unprocessed.where(arel_table[:calculate_after].lteq(Date.current))
    end

    def self.iterations
      24
    end

    def self.iteration_length
      :weeks
    end

    def self.census_iterations
      1
    end

    def self.census_iteration_length
      :months
    end

    def self.census_day
      15
    end

    # Start a new batch if we don't have one in the previous month
    def self.should_start_a_new_batch?
      # Date.current.day <= 7
      ! where(census: fifteenth_of_last_month).exists?
    end

    # If there are any that are ready for calculation
    def self.should_run?
      # Date.current.wday == 6
      where(calculated_on: nil).
        where(arel_table[:calculate_after].lt(Date.current)).exists?
    end

    def self.fifteenth_of_last_month
      1.months.ago.beginning_of_month.change(day: 15).to_date
    end

    def self.collection_dates_for_client client_id
      collections = []
      iterations.times do |iteration|
        iteration -= 1 # we want to start counting at 0
        calculate_after = Date.current + iteration.public_send(iteration_length)
        census_iterations.times do |census_iteration|
          # census_iteration -= 1 # we want to start counting at 0
          census_date = fifteenth_of_last_month - census_iteration.public_send(census_iteration_length)
          collections << {
            census: census_date,
            calculate_after: calculate_after,
            iteration: iteration + 1,
            of_iterations: iterations,
            resource_id: client_id,
            type: name,
          }
        end
      end
      collections
    end

    # Current purpose is as an aid in development and debugging
    def self.to_csv
      require 'csv'

      cols = ['id', 'type', 'resource_id', 'census', 'value', 'change', 'iteration', 'of_iterations']
      CSV.generate do |csv|
        csv << cols
        order(:id, :type, :resource_id, :census, :iteration).map do |r|
          csv << r.attributes.values_at(*cols)
        end
      end
    end

    # generally we'll set these up with create_batch!, but this
    # gives the option to create for one client
    def self.setup_for_client client_id
      collections = collection_dates_for_client(client_id)
      return unless collections.present?

      import(collections.first.keys, collections.map(&:values))
    end

    # For efficiency, import updates as a batch rather than as individual updates
    def self.create_batch!
      collections = []
      batch_scope.distinct.pluck(:client_id).each do |id|
        collections += collection_dates_for_client(id)
      end
      return unless collections.present?

      import(collections.first.keys, collections.map(&:values))
    end

    # Define in sub-class
    def self.batch_scope
      raise NotImplementedError
    end
  end
end
