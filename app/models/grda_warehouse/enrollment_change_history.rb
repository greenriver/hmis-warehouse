module GrdaWarehouse
  class EnrollmentChangeHistory < GrdaWarehouseBase
    include TsqlImport
    belongs_to :client
    validates_presence_of :on, :client_id

    def self.generate_for_date!(date: Date.today)
      range = ::Filters::DateRange.new(start: 1.years.ago, end: Date.today)
      GrdaWarehouse::Hud::Client.destination.distinct.
        joins(:source_enrollments).
        merge(GrdaWarehouse::Hud::Enrollment.open_during_range(range)).
        pluck_in_batches(:id, batch_size: 250) do |batch|
          Delayed::Job.enqueue(::Confidence::AddEnrollmentChangeHistoryJob.new(client_ids: batch, date: date), queue: :low_priority)
      end
    end

    def self.create_for_clients_on_date! client_ids:, date:
      clients = GrdaWarehouse::Hud::Client.destination.where(id: client_ids)
      rows = clients.map do |client|
        attributes_for_client_on_date(client: client, date: date)
      end
      self.new.insert_batch(self, rows.first.keys, rows.map(&:values), transaction: false)
    end

    def self.attributes_for_client_on_date client:, date:
      {
        client_id: client.id, 
        on: date,
        residential: client.enrollments_for_rollup(en_scope: client.scope_for_residential_enrollments).to_json,
        other: client.enrollments_for_rollup(en_scope: client.scope_for_other_enrollments).to_json,
        days_homeless: client.days_homeless,
        created_at: Time.now,
        updated_at: Time.now,
        version: 1,
      }
    end
  end
end
