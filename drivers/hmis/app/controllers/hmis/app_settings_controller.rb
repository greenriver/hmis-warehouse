###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class Hmis::AppSettingsController < Hmis::BaseController
  skip_before_action :authenticate_user!
  prepend_before_action :skip_timeout

  def show
    okta_enabled = ENV['HMIS_OKTA_CLIENT_ID'].present? && ENV['OKTA_DOMAIN'].present?

    logo = ENV['LOGO']
    if logo.present?
      logo_path = SerializedAsset.exists?(logo) ? SerializedAsset.get_src(logo) : "theme/logo/#{logo}"
    end

    hostname = ENV['FQDN']

    themes = GrdaWarehouse::Theme.where(client: ENV['CLIENT']&.to_sym).where.not(hmis_value: nil)
    themes = themes.where(origin: current_hmis_host) if themes.size > 1

    render json: {
      oktaPath: okta_enabled ? '/hmis/users/auth/okta' : nil,
      logoPath: logo_path.present? ? ActionController::Base.helpers.asset_path(logo_path) : nil,
      warehouseUrl: "https://#{hostname}",
      warehouseName: _('Boston DND Warehouse'),
      appName: _('Open Path HMIS'),
      resetPasswordUrl: "https://#{hostname}/users/password/new",
      unlockAccountUrl: "https://#{hostname}/users/unlock/new",
      manageAccountUrl: "https://#{hostname}/account/edit",
      casUrl: GrdaWarehouse::Config.get(:cas_url),
      theme: themes.first&.hmis_value,
      globalFeatureFlags: {
        # Whether to show MCI ID in client search results
        mciId: HmisExternalApis::AcHmis::Mci.enabled?,
        # Whether to show Referral and Denial screens
        externalReferrals: HmisExternalApis::AcHmis::Mper.enabled?,
      },
    }
  end
end
