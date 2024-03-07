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
    object_key = params[:object_key]
    definition = Hmis::Form::Definition.where(external_form_object_key: object_key).first!

    if params[:freshen_from_file]
      file_path = Rails.root.join("drivers/hmis/lib/form_data/tarrant_county/external_forms/#{File.basename(object_key)}.json")
      definition.definition = JSON.parse(File.read(file_path))
      Hmis::Form::Definition.validate_json(definition.definition) { |msg| raise msg }
      definition.title = definition.definition['name']
      definition.save!
    end

    HmisExternalApis::PublishExternalFormsJob.new.perform(definition.id)
    definition.reload
    publication = definition.external_form_publications.last!
    return render(html: publication.content.html_safe)
  end

  def create
    definition_id = params['form_definition_id']
    decoded_definition_id = definition_id ? ProtectedId::Encoder.decode(definition_id) : nil

    definition = Hmis::Form::Definition.find(decoded_definition_id)
    raw_data = params.to_unsafe_h
    submission = HmisExternalApis::ExternalForms::FormSubmission.from_raw_data(
      raw_data,
      object_key: SecureRandom.uuid,
      last_modified: Time.current,
      form_definition: definition,
    )

    render json: { id: submission.id }
  end
end