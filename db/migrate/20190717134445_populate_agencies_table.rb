class PopulateAgenciesTable < ActiveRecord::Migration
  def up
    User.all.find_each do |user|
      if user.agency.present?
        agency = Agency.where(name: user.agency).first_or_create
        user.update(agency_id: agency.id)
      end
    end
  end
end
