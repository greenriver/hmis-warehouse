class CreateExternalHmisConfiguration < ActiveRecord::Migration[7.0]
  def change
    create_table :external_hmis_configurations do |t|
      t.references :data_source, unique: true
      t.string :vendor
      t.string :base_url
      t.string :path_client, comment: 'something like: /clients/:client_token:/profile'
      t.string :path_enrollment
      t.string :path_project

      t.timestamps
    end
  end
end
