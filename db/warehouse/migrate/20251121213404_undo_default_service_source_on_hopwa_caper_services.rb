# frozen_string_literal: true

class UndoDefaultServiceSourceOnHopwaCaperServices < ActiveRecord::Migration[7.1]
  def change
    safety_assured do
      change_column_default :hopwa_caper_services, :service_source, from: 'hud_service', to: nil
    end
  end
end
