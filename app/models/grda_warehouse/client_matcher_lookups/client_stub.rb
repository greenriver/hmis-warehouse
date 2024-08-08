###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# efficiently query a large set of client records into memory-efficient objects
module GrdaWarehouse::ClientMatcherLookups
  ClientStub = Struct.new(:id, :first_name, :last_name, :ssn, :dob) do
    def self.from_scope(clients, id_field: :id, batch_size: 5_000)
      clients.in_batches(of: batch_size) do |batch|
        batch.pluck(id_field, :FirstName, :LastName, :SSN, :DOB).each do |attrs|
          client = ClientStub.new(*attrs)
          yield(client)
        end
      end
    end
  end
end
