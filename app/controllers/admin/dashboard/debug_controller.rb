module Admin::Dashboard
  class DebugController < ApplicationController
    include ArelHelper
    before_action :require_can_view_imports!
    def index
      @missing_destinations = GrdaWarehouse::WarehouseClient.where.not(destination_id: client_source.select(:id)).count
      @missing_sources = GrdaWarehouse::WarehouseClient.where.not(source_id: GrdaWarehouse::Hud::Client.select(:id)).count
      @missing_client_destinations = client_source.destination.where.not(id: GrdaWarehouse::WarehouseClient.select(:destination_id)).count
      @duplicate_source_items = check_for_hud_primary_key_duplicates
    end

    # Find any instances where we have duplicate entries within a given 
    # data source based on the HUD primary key
    private def check_for_hud_primary_key_duplicates
      {}.tap do |m|
        data_source_scope.each do |ds|
          m[ds.name] ||= {}
          GrdaWarehouse::Hud.models_by_hud_filename.values.each do |klass|
            errors = klass.where(data_source_id: ds.id)
              .group(klass.hud_primary_key)
              .having( nf( 'COUNT', [klass.arel_table[klass.hud_primary_key.to_sym]] ).gt 1 ) # .having("count(#{klass.hud_primary_key}) > 1")
              .count.size
            if errors > 0
              m[ds.name][klass.table_name] ||= {}
              m[ds.name][klass.table_name][:errors] = errors 
              m[ds.name][klass.table_name][:data_source_id] = ds.id
              m[ds.name][klass.table_name][:primary_hud_key] = klass.hud_primary_key
            end
          end
          m.delete(ds.name) if m[ds.name].empty? 
        end
      end
    end

    private def client_source 
      GrdaWarehouse::Hud::Client
    end

    private def warehouse_client_source
      GrdaWarehouse::WarehouseClient
    end

    private def data_source_scope
      GrdaWarehouse::DataSource.importable
    end
  end
end