class AddAcceptableDomainsToAgencies < ActiveRecord::Migration[4.2]
  def change
    add_column :agencies, :acceptable_domains, :string
  end
end
