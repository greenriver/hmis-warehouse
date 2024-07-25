###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

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

    ActionController::Renderer::RACK_KEY_TRANSLATION['warden'] ||= 'warden'
    warden_proxy = Warden::Proxy.new({}, Warden::Manager.new({})).tap do |i|
      i.set_user(current_user, scope: :user, store: false, run_callbacks: false)
    end

    renderer = controller_class.renderer.new(
      'warden' => warden_proxy,
    )
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
