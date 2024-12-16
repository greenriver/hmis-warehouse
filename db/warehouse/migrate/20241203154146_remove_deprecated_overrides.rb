class RemoveDeprecatedOverrides < ActiveRecord::Migration[7.0]
  def change
    safety_assured do
      drop_project_type_index
      drop_cols
    end
  end

  protected

  def drop_cols
    [
      ['Inventory', 'coc_code_override', :string],
      ['Inventory', 'inventory_start_date_override', :date],
      ['Inventory', 'inventory_end_date_override', :date],
      ['Project', 'act_as_project_type', :integer],
      ['Project', 'hud_continuum_funded', :boolean],
      ['Project', 'housing_type_override:', :integer],
      ['Project', 'operating_start_date_override', :date],
      ['Project', 'operating_end_date_override', :date],
      ['Project', 'hmis_participating_project_override', :integer],
      ['Project', 'target_population_override', :integer],
      ['Project', 'tracking_method_override', :integer], # extra
      ['ProjectCoC', 'hud_coc_code', :string],
      ['ProjectCoC', 'geography_type_override', :integer],
      ['ProjectCoC', 'geocode_override', :string],
      ['ProjectCoC', 'zip_override', :string],
    ].each do |table, field, _type|
      # remove_column table, field, type, if_exists: true
      reversible do |dir|
        deleted_field = "deleted_#{field}"
        dir.up do
          rename_column table, field, deleted_field if column_exists?(table, field)
        end
        dir.down do
          rename_column table, deleted_field, field if column_exists?(table, deleted_field)
        end
      end
    end
  end

  def drop_project_type_index
    reversible do |dir|
      dir.up do
        remove_index 'Project', name: 'project_project_override_index'
      end
      dir.down do
        execute('CREATE INDEX project_project_override_index ON public."Project" USING btree (COALESCE(act_as_project_type, "ProjectType"))')
      end
    end
  end
end
