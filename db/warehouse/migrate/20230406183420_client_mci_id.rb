class ClientMciId < ActiveRecord::Migration[6.1]
  def change
    # create_table :external_ids do
    #  t.string :external_id
    #  t.references :owner, polymorphic: true # (Client, Project, etc.)
    #  t.references :external_system # (MCI, MPER, etc.) (or could be a string..)
    #  t.references :data_source
    #  t.timestamps
    # end
    #
    # Any uniqueness constraints?
    # Hmis::Hud::Client should have “has many” relation to external client ids

  end
end
