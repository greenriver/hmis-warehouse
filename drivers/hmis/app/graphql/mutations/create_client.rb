module Mutations
  class CreateClient < BaseMutation
    argument :input, Types::HmisSchema::ClientInput, required: true

    type Types::HmisSchema::Client

    def resolve(input:)
      user = Hmis::Hud::User.where(UserEmail: current_user.email, data_source_id: current_user.hmis_data_source_id).first_or_create do |u|
        u.UserID = current_user.id
        u.UserFirstName = current_user.first_name
        u.UserLastName = current_user.last_name
        u.data_source_id = current_user.hmis_data_source_id
      end

      client = Hmis::Hud::Client.create!(
        data_source_id: user.data_source_id,
        UserID: user.UserID,
        PersonalID: SecureRandom.uuid.gsub(/-/, ''),
        **input.to_params,
      )

      GrdaWarehouse::Tasks::IdentifyDuplicates.new.run!
      # TODO: Disable client deletion if the data source is an HMIS data source

      client
    end
  end
end
