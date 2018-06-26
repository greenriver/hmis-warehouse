class MakeSiteAView < ActiveRecord::Migration
  def change
    rename_table :Site, :Geography
    create_view :Site, sql_definition: 'select * from "Geography"'
  end
end
