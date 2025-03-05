# frozen_string_literal: true

class AddProjectIdToHudClients < ActiveRecord::Migration[7.0]
  def change
    ['hud_report_dq_clients', 'hud_report_path_clients'].each do |table|
      add_column table, :project_id, :integer
    end
  end
end
