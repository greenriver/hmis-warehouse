# frozen_string_literal: true

module HudSpmReport
  class Mailer < ::ApplicationMailer
    def export_ready(user, blob, name)
      @user = user
      @name = name
      # Use rails_blob_url to generate a signed, temporary URL for download
      @url = Rails.application.routes.url_helpers.rails_blob_url(blob, disposition: :attachment)

      mail(to: @user.email, subject: "Your SPM Export is Ready: #{@name}")
    end
  end
end
