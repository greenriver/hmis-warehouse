class PopulateAgenciesTable < ActiveRecord::Migration
  def up
    User.all.find_each do |user|
      agency_name = if user.class.column_names.include?('agency')
        user[:agency]
        elsif user.class.column_names.include?('deprecated_agency')
          user.deprecated_agency
        end
      if agency_name.present?
        agency = Agency.where(name: agency_name).first_or_create
        user.update(agency_id: agency.id)
      end
    end
  end
end
