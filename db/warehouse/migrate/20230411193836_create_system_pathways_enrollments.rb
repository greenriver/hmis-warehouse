class CreateSystemPathwaysEnrollments < ActiveRecord::Migration[6.1]
  def change
    remove_column :system_pathways_clients, :es, :boolean
    remove_column :system_pathways_clients, :sh, :boolean
    remove_column :system_pathways_clients, :th, :boolean
    remove_column :system_pathways_clients, :rrh, :boolean
    remove_column :system_pathways_clients, :psh, :boolean
    remove_column :system_pathways_clients, :oph, :boolean
    remove_column :system_pathways_clients, :ph, :boolean
    remove_column :system_pathways_clients, :returned, :integer

    # Destination categories
    add_column :system_pathways_clients, :destination_homeless, :boolean, default: false
    add_column :system_pathways_clients, :destination_temporary, :boolean, default: false
    add_column :system_pathways_clients, :destination_institutional, :boolean, default: false
    add_column :system_pathways_clients, :destination_other, :boolean, default: false
    add_column :system_pathways_clients, :destination_permanent, :boolean, default: false

    add_column :system_pathways_clients, :returned_project_type, :integer
    add_column :system_pathways_clients, :returned_project_name, :string
    add_column :system_pathways_clients, :returned_project_entry_date, :date
    add_column :system_pathways_clients, :returned_project_enrollment_id, :integer
    add_column :system_pathways_clients, :returned_project_project_id, :integer

    # # System
    # add_column :system_pathways_clients, :system_to_es, :boolean, default: false
    # add_column :system_pathways_clients, :system_to_sh, :boolean, default: false
    # add_column :system_pathways_clients, :system_to_rrh, :boolean, default: false
    # add_column :system_pathways_clients, :system_to_th, :boolean, default: false
    # add_column :system_pathways_clients, :system_to_psh, :boolean, default: false
    # add_column :system_pathways_clients, :system_to_oph, :boolean, default: false
    # add_column :system_pathways_clients, :system_to_ph, :boolean, default: false
    # add_column :system_pathways_clients, :system_to_other, :boolean, default: false
    # # ES
    # add_column :system_pathways_clients, :es_to_rrh, :boolean, default: false
    # add_column :system_pathways_clients, :es_to_th, :boolean, default: false
    # add_column :system_pathways_clients, :es_to_psh, :boolean, default: false
    # add_column :system_pathways_clients, :es_to_oph, :boolean, default: false
    # add_column :system_pathways_clients, :es_to_ph, :boolean, default: false
    # add_column :system_pathways_clients, :es_to_exit, :boolean, default: false
    # # SH
    # add_column :system_pathways_clients, :sh_to_rrh, :boolean, default: false
    # add_column :system_pathways_clients, :sh_to_th, :boolean, default: false
    # add_column :system_pathways_clients, :sh_to_psh, :boolean, default: false
    # add_column :system_pathways_clients, :sh_to_oph, :boolean, default: false
    # add_column :system_pathways_clients, :sh_to_ph, :boolean, default: false
    # add_column :system_pathways_clients, :sh_to_exit, :boolean, default: false
    # # TH
    # add_column :system_pathways_clients, :th_to_rrh, :boolean, default: false
    # add_column :system_pathways_clients, :th_to_psh, :boolean, default: false
    # add_column :system_pathways_clients, :th_to_oph, :boolean, default: false
    # add_column :system_pathways_clients, :th_to_ph, :boolean, default: false
    # add_column :system_pathways_clients, :th_to_exit, :boolean, default: false
    # # RRH
    # add_column :system_pathways_clients, :rrh_to_psh, :boolean, default: false
    # add_column :system_pathways_clients, :rrh_to_oph, :boolean, default: false
    # add_column :system_pathways_clients, :rrh_to_ph, :boolean, default: false
    # add_column :system_pathways_clients, :rrh_to_exit, :boolean, default: false
    # # PH
    # add_column :system_pathways_clients, :psh_to_exit, :boolean, default: false
    # add_column :system_pathways_clients, :oph_to_exit, :boolean, default: false
    # add_column :system_pathways_clients, :ph_to_exit, :boolean, default: false

    create_table :system_pathways_enrollments do |t|
      t.references :client, null: false
      t.integer :from_project_type, comment: 'null for System'
      t.references :project, null: false
      t.references :enrollment, null: false
      t.integer :project_type, null: false
      t.integer :destination, comment: 'Only stored for final enrollment'
      t.string :project_name
      t.date :entry_date
      t.date :exit_date
      t.integer :stay_length
      t.timestamps
    end
  end
end
