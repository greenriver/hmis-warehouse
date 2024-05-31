###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module GrdaWarehouse
  class EnrollmentChangeHistory < GrdaWarehouseBase
    belongs_to :client, class_name: 'GrdaWarehouse::Hud::Client'
    validates_presence_of :on, :client_id

    RETENTION_DURATION = 6.months
    scope :expired_as_of, ->(date) {
      expiration_date = date - RETENTION_DURATION
      where(on: ...expiration_date)
    }

    def self.generate_for_date!(date: Date.current)
      priority = 12
      range = ::Filters::DateRange.new(start: 1.years.ago, end: Date.current)
      GrdaWarehouse::Hud::Client.destination.distinct.
        joins(:source_enrollments).
        merge(GrdaWarehouse::Hud::Enrollment.open_during_range(range)).
        pluck_in_batches(:id, batch_size: 20) do |batch|
          ::Confidence::AddEnrollmentChangeHistoryJob.set(priority: priority).perform_later(client_ids: batch, date: date.to_s)
        end

      # we'd like to run this after the other jobs are completed since it locks the table. There isn't a good way to
      # know when the other jobs have completed so we use a lower priority job scheduled for the future
      ::Confidence::PruneEnrollmentChangeHistoryJob.
        set(priority: priority + 1, run_at: date + 1.hour).
        perform_later(date: date.to_s)
    end

    def self.create_for_clients_on_date! client_ids:, date:
      clients = GrdaWarehouse::Hud::Client.destination.where(id: client_ids)
      rows = clients.map do |client|
        attributes_for_client_on_date(client: client, date: date) rescue nil # rubocop:disable Style/RescueModifier
      end.compact

      import(rows.first.keys, rows.map(&:values)) if rows.present?
    end

    def self.attributes_for_client_on_date client:, date:
      attributes_for_client = {
        client_id: client.id,
        on: date,
        # are timestamps and version columns used? This table is large; perhaps they could be dropped for efficiency
        created_at: Time.now,
        updated_at: Time.now,
        version: 1,
      }
      attributes_for_client[:residential] = client.enrollments_for_rollup(en_scope: client.scope_for_residential_enrollments(current_user), user: User.setup_system_user).to_json rescue '[]' # rubocop:disable Style/RescueModifier
      attributes_for_client[:other] = client.enrollments_for_rollup(en_scope: client.scope_for_other_enrollments(current_user), user: User.setup_system_user).to_json rescue '[]' # rubocop:disable Style/RescueModifier
      attributes_for_client[:days_homeless] = client.days_homeless rescue 0 # rubocop:disable Style/RescueModifier
      return attributes_for_client
    end
  end
end
