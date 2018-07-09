class AddDsRelationships < ActiveRecord::Migration
  def up

    ds = Health::DataSource.where(name: 'BHCHP EPIC').first_or_create
    Health::DataSource.where(name: 'Patient Referral').first_or_create

    add_reference :patients, :data_source, null: false, default: ds.id
    add_reference :medications, :data_source, null: false, default: ds.id
    add_reference :problems, :data_source, null: false, default: ds.id
    add_reference :appointments, :data_source, null: false, default: ds.id
    add_reference :visits, :data_source, null: false, default: ds.id
    add_reference :epic_goals, :data_source, null: false, default: ds.id
  end
  def down
    remove_reference :patients, :data_source
    remove_reference :medications, :data_source
    remove_reference :problems, :data_source
    remove_reference :appointments, :data_source
    remove_reference :visits, :data_source
    remove_reference :epic_goals, :data_source
    Health::DataSource.where(name: 'BHCHP EPIC').delete_all
     Health::DataSource.where(name: 'Patient Referral').delete_all
  end
end
