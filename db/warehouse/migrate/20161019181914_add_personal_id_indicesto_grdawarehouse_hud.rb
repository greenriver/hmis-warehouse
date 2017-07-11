class AddPersonalIdIndicestoGrdawarehouseHud < ActiveRecord::Migration
  TABLES = [   # all the tables I found which had PersonalID
    GrdaWarehouse::Hud::Client,
    GrdaWarehouse::Hud::Disability,
    GrdaWarehouse::Hud::EmploymentEducation,
    GrdaWarehouse::Hud::Enrollment,
    GrdaWarehouse::Hud::EnrollmentCoc,
    GrdaWarehouse::Hud::Exit,
    GrdaWarehouse::Hud::HealthAndDv,
    GrdaWarehouse::Hud::IncomeBenefit,
    GrdaWarehouse::Hud::Service
  ]

  COLS = %w( data_source_id PersonalID )

  def up
    TABLES.each do |m|
      idxes = m.connection.indexes(m.table_name)
      existing = idxes.select{ |idx| ( idx.columns & COLS ).length == COLS.length }
      next if existing.any?
      add_index m.table_name, COLS, name: christen(m)
    end
  end

  def down
    TABLES.each do |m|
      n = christen(m)
      idxes = m.connection.indexes(m.table_name)
      next unless idxes.any?{ |idx| idx.name == n && ( idx.columns & COLS ).length == COLS.length }
      remove_index m.table_name, name: n
    end
  end

  def christen(m)
    "index_#{m.table_name}_on_data_source_id_PersonalID"
  end
end
