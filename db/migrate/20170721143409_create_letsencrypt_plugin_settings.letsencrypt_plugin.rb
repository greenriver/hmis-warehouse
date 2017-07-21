# This migration comes from letsencrypt_plugin (originally 20160412195212)
class CreateLetsencryptPluginSettings < ActiveRecord::Migration
  def change
    return if ActiveRecord::Base.connection.table_exists? :letsencrypt_plugin_settings
    create_table :letsencrypt_plugin_settings do |t|
      t.text :private_key

      t.timestamps null: false
    end
  end
end
