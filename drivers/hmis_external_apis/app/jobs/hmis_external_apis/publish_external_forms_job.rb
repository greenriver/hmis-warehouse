###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'nokogiri'

# render and upload static forms
#
# currently this needs to be run manually
class HmisExternalApis::PublishExternalFormsJob
  include SafeInspectable

  def perform(definition_id)
    definition = Hmis::Form::Definition.where(role: :EXTERNAL_FORM).published.find(definition_id)
    # Validate the form structure and CDEDs
    validate_form!(definition)
    # Validate the external forms setup
    missing_config = HmisExternalApis::ExternalForms::Config.validate_external_forms_setup
    raise "external forms feature is not properly configured: #{missing_config.join(', ')}" if missing_config.any? && (Rails.env.production? || Rails.env.staging?)

    publication = definition.external_form_publications.new

    renderer = HmisExternalApis::ExternalFormsController.renderer.new
    raw_content = renderer.render('hmis_external_apis/external_forms/form', assigns: { form_definition: definition, page_title: definition.title })

    publication.object_key = definition.external_form_object_key
    publication.content_digest = digest = Digest::MD5.hexdigest(raw_content)
    publication.content = process_content(raw_content, digest: digest, definition_id: definition.id)
    publication.content_definition = definition.definition

    upload_to_s3(publication)

    publication.save!
    publication
  end

  protected

  def validate_form!(definition)
    raise 'form must have external_form_object_key' unless definition.external_form_object_key.present?
    raise 'form must be published in Form Builder first' unless definition.published? # must publish in Form Builder first

    # Validate the form structure and CDEDs
    errors = Hmis::Form::DefinitionValidator.perform(definition.definition, data_source_id: data_source_id)
    raise "cannot publish form with errors: #{errors.full_messages.join(', ')}" if errors.any?
  end

  def user_id
    @user_id ||= Hmis::Hud::User.system_user(data_source_id: data_source_id).user_id
  end

  def data_source_id
    # TODO(#6691) - update this to use the FormDefinition's data source once that column is added
    @data_source_id ||= GrdaWarehouse::DataSource.hmis.first.id
  end

  # prepare form content for publication
  def process_content(raw_content, digest:, definition_id:)
    doc = Nokogiri::HTML5(raw_content)

    forms = doc.css('form')
    raise 'expected one form' unless forms.one?

    form = forms.first
    form.add_child(%(<input type="hidden" name="form_content_digest" value="#{digest}">))
    protected_definition_id = ProtectedId::Encoder.encode(definition_id)
    form.add_child(%(<input type="hidden" name="form_definition_id" value="#{protected_definition_id}">))

    doc.xpath('//comment()').each(&:remove)
    doc.to_html
  end

  def upload_to_s3(publication)
    return if Rails.env.development? || Rails.env.test?

    # use bucket/object rather than AwsS3 methods here since we want to publish the form without access restrictions.
    # Maybe this could be DRYed up in the future if we find more use cases
    object = s3.bucket.object(publication.object_key)
    object.put(
      body: publication.content,
      acl: 'public-read',
      content_disposition: 'inline',
      content_type: 'text/html; charset=utf-8',
    )
  end

  def s3
    @s3 ||= GrdaWarehouse::RemoteCredentials::S3.for_active_slug('public_bucket').s3
  end
end
