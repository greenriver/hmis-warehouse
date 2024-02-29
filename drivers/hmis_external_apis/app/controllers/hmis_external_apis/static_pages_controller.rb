###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class HmisExternalApis::StaticPagesController < ActionController::Base
  before_action do
    # this is intended for development. See PublishStaticFormsJob for production usage
    raise unless Rails.env.development?
  end

  include ::HmisExternalApis::StaticPagesHelper
  skip_before_action :verify_authenticity_token

  layout 'hmis_external_apis/static_pages'
  # these pages have inline csp meta tags
  content_security_policy false

  def presign
    render json: {url: create_hmis_external_apis_static_page_path}
  end

  def show
    template = params[:template]
    definition = HmisExternalApis::StaticPages::FormDefinition.from_file(template).publish!
    return render(html: definition.content.html_safe)
  end

  def create
    definition_id = params['form_definition_id']
    decoded_definition_id = definition_id ? ProtectedId::Encoder.decode(definition_id) : nil
    HmisExternalApis::StaticPages::FormSubmission.create!(
      submitted_at: Time.current,
      spam_score: 0,
      status: 'new',
      form_definition_id: decoded_definition_id,
      object_key: SecureRandom.uuid,
      data: params.to_unsafe_h,
    )
    render json: params
  end
end
