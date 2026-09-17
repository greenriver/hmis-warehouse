# frozen_string_literal: true

# HUD reports are now report definitions gated by collections; see
# GrdaWarehouse::Tasks::GrantAllHudReports for how existing access is carried over.
class GrantAllHudReportsToHudReportRoles < ActiveRecord::Migration[8.1]
  def up
    GrdaWarehouse::Tasks::GrantAllHudReports.new.run!
  end

  # Access grants are additive; roll back by deleting the HUD Report Viewer access controls by hand.
  def down
  end
end
