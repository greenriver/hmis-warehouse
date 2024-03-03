###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class HmisExternalApis::ExternalFormsController < ActionController::Base
  include ::HmisExternalApis::ExternalFormsHelper

  before_action do
    # Only allow calling the controller directly in development. See PublishExternalFormsJob for production usage
    raise unless Rails.env.development?
  end

  skip_before_action :verify_authenticity_token

  layout 'hmis_external_apis/external_forms'
  # these pages have inline csp meta tags
  content_security_policy false

  def presign
    render json: { url: create_hmis_external_apis_external_form_path }
  end

  def show
    # to refresh form content
    # exec rake driver:hmis_external_apis:tc_hmis:seed_external_forms
    object_key = params[:object_key]
    definition = Hmis::Form::Definition.where(external_form_object_key: object_key).first!
    publication = definition.external_form_publications.last!
    return render(html: publication.content.html_safe)
  end

  def create
    definition_id = params['form_definition_id']
    decoded_definition_id = definition_id ? ProtectedId::Encoder.decode(definition_id) : nil
    HmisExternalApis::ExternalForms::FormSubmission.create!(
      submitted_at: Time.current,
      spam_score: 0,
      status: 'new',
      definition_id: decoded_definition_id,
      object_key: SecureRandom.uuid,
      raw_data: params.to_unsafe_h,
    )
    render json: params
  end
end
