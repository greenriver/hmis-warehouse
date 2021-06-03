class CreateSimpleReportUniverseMembers < ActiveRecord::Migration[5.2]
  def change
    create_table :simple_report_universe_members do |t|
      t.references :report_cell
      t.references :universe_membership, polymorphic: true, index: { name: :simple_report_univ_type_and_id }

      t.references :client

      t.string :first_name
      t.string :last_name

      t.datetime :deleted_at
      t.timestamps
    end

    add_index :simple_report_universe_members, [:report_cell_id, :universe_membership_id, :universe_membership_type],
      unique: true,
      name: 'uniq_simple_report_universe_members',
      where: 'deleted_at IS NULL'
  end
end
