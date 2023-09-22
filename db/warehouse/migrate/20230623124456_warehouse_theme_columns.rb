class WarehouseThemeColumns < ActiveRecord::Migration[6.1]
  def change
    safety_assured { add_reference :themes, :remote_credential }
    add_column :themes, :css_file_contents, :text
    add_column :themes, :scss_file_contents, :text
  end
end
