module Mutations
  class CreateClient < BaseMutation
    argument :input, Types::HmisSchema::ClientInput, required: true

    type Types::HmisSchema::Client

    def resolve(input:)
      puts 'INPUT', input.to_params
      nil
      # user = Hmis::Hud::User.where(user_email: current_user.email, data_source_id: current_user.hmis_data_source_id).first_or_create do |u|
      #   u.user_id = current_user.id
      #   u.user_first_name = current_user.first_name
      #   u.user_last_name = current_user.last_name
      #   u.data_source_id = current_user.hmis_data_source_id
      # end

      # client = Hmis::Hud::Client.create!(
      #   data_source_id: user.data_source_id,
      #   user_id: user.user_id,
      #   personal_id: SecureRandom.uuid.gsub(/-/, ''),
      #   date_updated: DateTime.current,
      #   date_created: DateTime.current,
      #   **input.to_params,
      # )

      # GrdaWarehouse::Tasks::IdentifyDuplicates.new.delay.run!
      # # TODO: Disable client deletion if the data source is an HMIS data source

      # client
    end
  end
end
