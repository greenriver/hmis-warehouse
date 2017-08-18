class RenameYearsHomelessInVispdats < ActiveRecord::Migration
  def change
    rename_column :vispdats, :years_homeless, :homeless
    rename_column :vispdats, :years_homeless_refused, :homeless_refused
    add_column :vispdats, :homeless_period, :integer

    rename_column :vispdats, :consent, :hiv_release
    add_column :vispdats, :release_signed_on, :date
    add_column :vispdats, :drug_release, :boolean
  end
end
