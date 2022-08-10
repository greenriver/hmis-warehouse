###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class HealthMailer < DatabaseMailer
  def shared_health_mailer_options
    {
      from: health_from,
      delivery_method_options: {
        address: health_smtp_server,
        user_name: health_smtp_username,
        password: health_smtp_password,
      },
    }.freeze
  end

  private def health_smtp_configuration
    GrdaWarehouse::RemoteConfigs::HealthMailer.first&.remote_credential
  end

  private def health_smtp_server
    health_smtp_configuration&.server || ENV['SMTP_SERVER']
  end

  private def health_smtp_username
    health_smtp_configuration&.username || ENV['SMTP_USERNAME']
  end

  private def health_smtp_password
    health_smtp_configuration&.password || ENV['SMTP_PASSWORD']
  end

  private def health_from
    health_smtp_configuration&.from || ENV['HEALTH_FROM']
  end
end
