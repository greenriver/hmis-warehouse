###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class BackgroundRender::CasReadinessJob < BackgroundRenderJob
  def render_html(client_id:, user_id:)
    current_user = User.find(user_id)
    @client = GrdaWarehouse::Hud::Client.destination_from_searchable_to(current_user).
      preload(
        :source_exits,
        source_enrollments: [
          :exit,
          :income_benefits,
        ],
      ).
      find(client_id.to_i)

    Clients::CasReadinessController.render(
      partial: :render_content,
      assigns: {
        client: @client,
      },
      locals: {
        current_user: current_user,
      },
    )
  end
end
