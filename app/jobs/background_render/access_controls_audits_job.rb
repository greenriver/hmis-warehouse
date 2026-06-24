###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class BackgroundRender::AccessControlsAuditsJob < BackgroundRenderJob
  include AccessControlAuditData

  def render_html(user_id:)
    current_user = User.find(user_id)

    # Recreate the data processing logic from the controller
    histories = build_histories(current_user)
    data = build_data(histories)

    Admin::AccessControlsController.render(
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
