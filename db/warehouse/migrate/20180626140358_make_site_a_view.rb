class MakeSiteAView < ActiveRecord::Migration
  def up
    rename_table :Site, :Geography
    rename_column :Geography, :SiteID, :GeographyID
    rename_column :Geography, :Address, :Address1
    create_view :Site, sql_definition: 'select * from "Geography"'
  end

  def down
    drop_view :Site
    rename_column :Geography, :GeographyID, :SiteID
    rename_column :Geography, :Address1, :Address
    rename_table :Geography, :Site
  end
end
