###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class BackgroundRender::CasReadinessJob < BackgroundRenderJob
  queue_as ENV.fetch('DJ_SHORT_QUEUE_NAME', :short_running)

  def render_html(client_id:, user_id:, token:)
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

    renderer = controller_class.renderer.new(WardenProxyFactory.renderer_env(current_user))
    html = renderer.render(
      partial: 'render_content',
      assigns: {
        client: @client,
        token: token,
      },
      locals: {
        current_user: current_user,
      },
    )
    html
  end

  def controller_class
    Clients::CasReadinessController
  end
end
