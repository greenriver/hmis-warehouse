###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md

require 'nokogiri'

# render and upload static forms
#
# currently this needs to be run manually
class HmisExternalApis::PublishExternalFormsJob
  # queue_as ENV.fetch('DJ_LONG_QUEUE_NAME', :long_running)
  include SafeInspectable

  def perform(definition_id)
    definition = Hmis::Form::Definition.find(definition_id)
    raise unless definition.external_form_object_key.present?

    # In order to publish to S3, the form should already be published in HMIS (ideally via Form Builder)
    raise "cannot publish form with status #{definition.status}" unless definition.published?

    publication = definition.external_form_publications.new

    renderer = HmisExternalApis::ExternalFormsController.renderer.new
    raw_content = renderer.render('hmis_external_apis/external_forms/form', assigns: { form_definition: definition.definition, page_title: definition.title })

    publication.object_key = definition.external_form_object_key
    publication.content_digest = digest = Digest::MD5.hexdigest(raw_content)
    publication.content = process_content(raw_content, digest: digest, definition_id: definition.id)
    publication.content_definition = definition.definition

    # Note: Most likely, the form was already published using the Form Builder, so the CDEDs have already been created.
    # Future improvement would be to invoke this job from publish mutation so that External Forms can be published to S3 from the config tool.
    update_cdeds(definition)

    upload_to_s3(publication)

    publication.save!
    publication
  end

  protected

  def user_id
    @user_id ||= Hmis::Hud::User.system_user(data_source_id: data_source_id).user_id
  end

  def data_source_id
    @data_source_id ||= GrdaWarehouse::DataSource.hmis.first.id
  end

  # construct custom data element definitions from the nodes in the form definition
  def update_cdeds(definition)
    Hmis::Hud::CustomDataElementDefinition.transaction do
      definition.introspect_custom_data_element_definitions(set_definition_identifier: true).each(&:save!)
    end
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
