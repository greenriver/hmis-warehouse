# these are just the GrdaWarehouse::Hud::Client table for *destination* clients, hiding the data_source_id column
class AddReportClientView < ActiveRecord::Migration
  def up
    # first make the destination client view
    # client_columns = ( clients.column_names - ['data_source_id'] ).map(&:to_sym)
    # create_view :report_clients, clients.destination.select(client_columns)
  end

  def down
    drop_view :report_clients
  end

  protected

    def clients
      GrdaWarehouse::Hud::Client
    end
end
