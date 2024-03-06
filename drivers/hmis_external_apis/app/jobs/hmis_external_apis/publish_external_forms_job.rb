###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md

require 'nokogiri'

# render and upload static forms
class HmisExternalApis::PublishExternalFormsJob
  include SafeInspectable

  def perform(definition_id)
    definition = Hmis::Form::Definition.find(definition_id)
    raise unless definition.external_form_object_key.present?

    publication = definition.external_form_publications.new

    renderer = HmisExternalApis::ExternalFormsController.renderer.new
    raw_content = renderer.render('hmis_external_apis/external_forms/form', assigns: { form_definition: definition.definition })

    publication.object_key = definition.external_form_object_key
    publication.content_digest = digest = Digest::MD5.hexdigest(raw_content)
    publication.content = process_content(raw_content, digest: digest, definition_id: definition.id)
    publication.content_definition = definition.definition

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
    owner_type = HmisExternalApis::ExternalForms::FormSubmission.sti_name
    cded_by_key = definition.custom_data_element_definitions.index_by(&:key)
    missing = []
    definition.walk_definition_nodes do |node|
      cded_key = node['link_id']
      attrs = nil
      case node['type']
      when 'STRING', 'CHOICE', 'BOOLEAN'
        # treat everything as a string for now
        attrs = {
          owner_type: owner_type,
          field_type: 'string',
          key: cded_key,
          label: cded_key.humanize,
          repeats: false,
          UserID: user_id,
          data_source_id: data_source_id,
          form_definition_identifier: definition.identifier,
        }
      end
      if attrs
        cded = cded_by_key[cded_key]
        cded ? cded.update!(attrs) : missing.push(attrs)
      end
    end
    Hmis::Hud::CustomDataElementDefinition.import!(missing, validate: false)
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
    bucket_name = ENV['S3_PUBLIC_BUCKET']
    if bucket_name.blank?
      raise 'missing public bucket for upload' unless Rails.env.development? || Rails.env.test?

      return
    end

    s3.put_object(
      bucket: bucket_name,
      key: publication.object_key,
      body: publication.content,
      content_type: 'text/html',
    )
  end

  def s3
    @s3 ||= Aws::S3::Client.new(
      access_key_id: ENV.fetch('S3_PUBLIC_ACCESS_KEY_ID'),
      secret_access_key: ENV.fetch('S3_PUBLIC_ACCESS_KEY_SECRET'),
    )
  end
end
