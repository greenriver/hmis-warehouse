module WarehouseReports
  class ManageCasFlagsController < ApplicationController

    def index
      @cas_active = hashed(
        client_source.cas_active.
          order(:LastName, :FirstName).
          pluck(*client_fields)
      )
      @han_release = hashed(
        client_source.han_release_on_file.
          order(:LastName, :FirstName).
          pluck(*client_fields)
      )
      @disabled = hashed(
        client_source.verified_disability.
          order(:LastName, :FirstName).
          pluck(*client_fields)
      )
    end

    def bulk_update
      flashes = []
      bulk_params.each do |column, value|
        client_ids = value.strip.split(/\s+/).uniq
        unflagged_count = unflag(column: column, client_ids: client_ids)
        flashes << "Removed <strong>#{client_source.cas_columns[column.to_sym]}</strong> from #{unflagged_count} clients".html_safe if unflagged_count > 0
        flagged_count = flag(column: column, client_ids: client_ids)
        flashes << "Added <strong>#{client_source.cas_columns[column.to_sym]}</strong> to #{flagged_count} clients".html_safe if flagged_count > 0
      end
      
      flash[:notice] = flashes.join('<br />').html_safe if flashes.any?
      redirect_to action: :index
    end

    def client_fields
      [
        :id,
        :FirstName,
        :LastName,
      ]
    end

    def bulk_params
      params.require(:cas_flags).permit(
        :sync_with_cas,
        :housing_assistance_network_released_on,
        :disability_verified_on
      )
    end

    def hashed(results)
      results.map do |row|
        Hash[client_fields.zip(row)]
      end
    end

    def unflag(column:, client_ids:)
      default = client_source.columns_hash[column].default
      client_source.where.not(column => default).
        where.not(id: client_ids).
        update_all(column => default)
    end

    def flag(column:, client_ids:)
      default = client_source.columns_hash[column].default
      set_to = if default === false
        true
      else
        Time.now
      end
      client_source.where(id: client_ids).
        where(column => default).
        update_all(column => set_to)
    end

    def client_source
      GrdaWarehouse::Hud::Client
    end
  end
end