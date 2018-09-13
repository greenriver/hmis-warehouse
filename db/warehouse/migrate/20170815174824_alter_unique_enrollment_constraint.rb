class AlterUniqueEnrollmentConstraint < ActiveRecord::Migration
  def change
    model = GrdaWarehouse::Hud::Enrollment
    cols = [:data_source_id, model.hud_csv_headers.first].map(&:to_s)
    #remove_index model.table_name, name: "unk_#{model.table_name}"
    cols = [:data_source_id, model.hud_csv_headers.first, :PersonalID].map(&:to_s)
    add_index model.table_name,  cols, name: "unk_#{model.table_name}", unique: true
  end
end
