class DropOldServiceHistoryServices < ActiveRecord::Migration[6.1]
  def up
    safety_assured do
      begin
        # Is this okay?
        execute("DROP VIEW IF EXISTS bi_service_history_services")

        execute("ALTER SEQUENCE service_history_services_id_seq OWNED BY service_history_services.id")

        # You might need to run this locally?
        # I don't want to impose something long-running in development, though.
        # GrdaWarehouse::ServiceHistoryServiceMaterialized.rebuild! if Rails.env.development?

        result = execute "select count(*) from service_history_services_was_for_inheritance"

        if result.to_a.first["count"].zero?
          drop_table :service_history_services_was_for_inheritance
        else
          raise "For some reason service_history_services_was_for_inheritance was not empty! Please check."
        end
      rescue ActiveRecord::StatementInvalid => e
        execute("ROLLBACK")
        Rails.logger.error "For some reason service_history_services_was_for_inheritance didn't exist or had dependencies. Ignoring drop attempt"
      end
    end
  end
end
