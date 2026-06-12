###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class BackgroundRender::HmisAccessControlsAuditsJob < BackgroundRenderJob
  include HmisAccessControlAuditData

  def render_html(user_id:)
    current_user = User.find(user_id)

    histories = build_histories
    data = build_data(histories)

    HmisAdmin::AccessControlsController.render(
      partial: 'audits_content',
      assigns: {
        data: data,
        current_user: current_user,
      },
      locals: {
        current_user: current_user,
      },
    )
  end
end
