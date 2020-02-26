class PopulateYouthIntakeName < ActiveRecord::Migration[5.2]
  def up
    GrdaWarehouse::YouthIntake::Base.find_each do |intake|
      client = intake.client
      next unless client

      intake.update_columns(
        first_name: client.FirstName,
        last_name: client.LastName,
        ssn: client.SSN,
      )
    end
  end
end
