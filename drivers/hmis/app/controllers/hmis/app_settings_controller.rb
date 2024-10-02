###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class Hmis::AppSettingsController < Hmis::BaseController
  skip_before_action :authenticate_hmis_user!
  prepend_before_action :skip_timeout

  def show
    okta_enabled = ENV['HMIS_OKTA_CLIENT_ID'].present? && ENV['OKTA_DOMAIN'].present?

    logo = ENV['HMIS_LOGO']&.presence || ENV['LOGO']&.presence # prefer HMIS_LOGO if provided, otherwise LOGO
    if logo.present?
      logo_path = SerializedAsset.exists?(logo) ? SerializedAsset.get_src(logo) : "theme/logo/#{logo}"
    end

    hostname = ENV['FQDN']

    # Note: the commented-out theme call doesn't work yet because request.origin is nil for this request.
    # So for now, multi-HMIS theming is not yet supported. Issue #6774
    # theme = GrdaWarehouse::Theme.hmis_theme_for_origin(current_hmis_host)
    theme = GrdaWarehouse::Theme.where(client: ENV['CLIENT']&.to_sym).filter(&:hmis_theme?).first

    render json: {
      oktaPath: okta_enabled ? '/hmis/users/auth/okta' : nil,
      logoPath: logo_path.present? ? ActionController::Base.helpers.asset_path(logo_path) : nil,
      warehouseUrl: "https://#{hostname}",
      warehouseName: Translation.translate('Boston DND Warehouse'),
      appName: Translation.translate('Open Path HMIS'), # TODO: app name should be configurable per data source
      resetPasswordUrl: "https://#{hostname}/users/password/new",
      unlockAccountUrl: "https://#{hostname}/users/unlock/new",
      manageAccountUrl: "https://#{hostname}/account/edit",
      casUrl: GrdaWarehouse::Config.get(:cas_url),
      revision: Git.revision,
      branch: Git.branch,
      theme: theme&.hmis_value,
      globalFeatureFlags: {
        # Whether to show MCI ID in client search results
        mciId: HmisExternalApis::AcHmis::Mci.enabled?,
        # Whether to show Referral and Denial screens
        externalReferrals: HmisExternalApis::AcHmis::Mper.enabled?,
      },
    }
  end
end
