class AddHudTableUniqueKeys < ActiveRecord::Migration
  HUD_TABLES = [
      GrdaWarehouse::Hud::Affiliation,
      GrdaWarehouse::Hud::Client,
      GrdaWarehouse::Hud::Disability,
      GrdaWarehouse::Hud::EmploymentEducation,
      GrdaWarehouse::Hud::Enrollment,
      # GrdaWarehouse::Hud::EnrollmentCoc,
      GrdaWarehouse::Hud::Exit,
      GrdaWarehouse::Hud::Export,
      GrdaWarehouse::Hud::Funder,
      GrdaWarehouse::Hud::HealthAndDv,
      GrdaWarehouse::Hud::IncomeBenefit,
      GrdaWarehouse::Hud::Inventory,
      GrdaWarehouse::Hud::Organization,
      GrdaWarehouse::Hud::Project,
      GrdaWarehouse::Hud::ProjectCoc,
      GrdaWarehouse::Hud::Service,
      GrdaWarehouse::Hud::Geography
    ]


  private def index_name(model, cols)
    "unk_#{model.table_name}"
  end

  def up
    # add unique indicies for each data_source_id and model key combo
    # remove any indicies made redundant by adding the new ones
    HUD_TABLES.each do |model|
      cols = [:data_source_id, model.hud_csv_headers.first].map(&:to_s)
      name = index_name(model, cols)
      model.connection.indexes(model.table_name).each do |idx|
        if idx.name != name && (idx.columns == cols && idx.columns == ['data_source_id'])
          remove_index model.table_name, name: idx.name
        end
      end
      add_index model.table_name, cols, name: name, unique: true rescue nil
    end
  end

  def down
    HUD_TABLES.each do |model|
      cols = [:data_source_id, model.hud_csv_headers.first]
      name = index_name(model, cols)
      remove_index model.table_name, name: name rescue nil
    end
  end
end
