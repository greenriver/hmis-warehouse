module GrdaWarehouse::Confidence
  class Base < GrdaWarehouseBase
    include TsqlImport
    include NotifierConfig

    self.table_name = :data_monitorings

    scope :unprocessed, -> do 
      where(value: nil)
    end

    scope :queued, -> do
      unprocessed.
      where(arel_table[:calculate_after].lteq(Date.today))
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

    # Start a new batch once a month
    # This should only run once a week, so it should only catch once a month
    def self.should_start_a_new_batch?
      Date.today.day <= 7      
    end


    # only run on Saturdays
    def self.should_run?
      Date.today.wday == 6
    end
    
    def self.collection_dates_for_client client_id
      most_recent_15th = if Date.today.day >= 15
        Date.today.beginning_of_month.change(day: 15).to_date
      else
        1.months.ago.beginning_of_month.change(day: 15).to_date
      end
      collections = []
      iterations.times do |iteration|
        iteration -= 1 # we want to start counting at 0
        calculate_after = Date.today + iteration.public_send(iteration_length)
        census_iterations.times do |census_iteration|
          census_iteration -= 1 # we want to start counting at 0
          census_date = most_recent_15th - census_iteration.public_send(census_iteration_length)
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

    # generally we'll set these up with create_batch!, but this 
    # gives the option to create for one client
    def self.setup_for_client client_id
      collections = collection_dates_for_client(client_id)
      self.new.insert_batch(self, collections.first.keys, collections.map(&:values))
    end

    def self.create_batch!
      collections = []
      batch_scope.pluck(:client_id).each do |id|
        collections += collection_dates_for_client(id)
      end
      self.new.insert_batch(self, collections.first.keys, collections.map(&:values))
    end

    # Define in sub-class
    def self.batch_scope
      raise NotImplementedError
    end
  end
end