class AddAcceptableDomainsToAgencies < ActiveRecord::Migration
  def change
    add_column :agencies, :acceptable_domains, :string
  end
end
