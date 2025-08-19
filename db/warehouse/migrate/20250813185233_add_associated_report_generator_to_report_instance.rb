# frozen_string_literal: true

class AddAssociatedReportGeneratorToReportInstance < ActiveRecord::Migration[7.1]
  def change
    add_column :hud_report_instances, :generator_class_name, :string
  end
end
