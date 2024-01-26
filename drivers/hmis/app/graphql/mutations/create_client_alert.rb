module Mutations
  class CreateClientAlert < CleanBaseMutation
    argument :id, ID, required: true
    argument :note, String, required: true
    argument :expiration_date, GraphQL::Types::ISO8601Date, required: false
    argument :priority, Types::HmisSchema::Enums::ClientAlertPriorityLevel, required: false

    field :client_alert, Types::HmisSchema::ClientAlert, null: true

    def resolve(id:, note:, expiration_date: nil, priority: nil)
      raise 'not allowed' unless current_user.can_manage_client_alerts

      client = Hmis::Hud::Client.viewable_by(current_user).find(id)
      client_alert = Hmis::ClientAlert.create!(
        client: client,
        created_by: current_user,
        note: note,
        created_at: Time.now,
        expiration_date: expiration_date&.end_of_day,
        priority: priority,
      )
      { client_alert: client_alert }
    end
  end
end
