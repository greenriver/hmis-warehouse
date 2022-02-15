###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Admin::Dashboard
  class DebugController < ApplicationController
    include ArelHelper
    before_action :require_can_view_imports!
    def index
      destination_ids = GrdaWarehouse::WarehouseClient.pluck(:destination_id)
      destination_client_ids = client_source.destination.pluck(:id)
      @missing_destinations = (destination_ids - destination_client_ids).size

      source_ids = GrdaWarehouse::WarehouseClient.pluck(:source_id)
      source_client_ids = client_source.source.pluck(:id)
      @missing_sources = (source_ids - source_client_ids).size

      @missing_client_destinations = (destination_client_ids - destination_ids).size
      @duplicate_source_items = [] # check_for_hud_primary_key_duplicates
    end

    # Find any instances where we have duplicate entries within a given
    # data source based on the HUD primary key
    def check_for_hud_primary_key_duplicates
      {}.tap do |m|
        data_source_scope.each do |ds|
          m[ds.name] ||= {}
          GrdaWarehouse::Hud.models_by_hud_filename.each_value do |klass|
            errors = klass.where(data_source_id: ds.id).
              group(klass.hud_primary_key).
              having(nf('COUNT', [klass.arel_table[klass.hud_primary_key.to_sym]]).gt(1)). # .having("count(#{klass.hud_primary_key}) > 1")
              count.size
            next unless errors.positive?

            m[ds.name][klass.table_name] ||= {}
            m[ds.name][klass.table_name][:errors] = errors
            m[ds.name][klass.table_name][:data_source_id] = ds.id
            m[ds.name][klass.table_name][:primary_hud_key] = klass.hud_primary_key
          end
          m.delete(ds.name) if m[ds.name].empty?
        end
      end
    end

    def client_source
      GrdaWarehouse::Hud::Client
    end

    def warehouse_client_source
      GrdaWarehouse::WarehouseClient
    end

    def data_source_scope
      GrdaWarehouse::DataSource.importable
    end
  end
end
