###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md

require 'nokogiri'

# render and upload static forms
class HmisExternalApis::PublishExternalFormsJob
  include SafeInspectable

  def perform(definition_id)
    definition = HmisExternalApis::ExternalForms::FormDefinition.find(definition_id)
    definition.validate_json!

    renderer = HmisExternalApis::ExternalFormsController.renderer.new
    raw_content = renderer.render("hmis_external_apis/external_forms/form", assigns: {form_definition: definition.data})

    digest = Digest::MD5.hexdigest(raw_content)
    versioned_content = process_content(definition, raw_content)
    object_key = upload_to_s3(definition)

    definition.attributes = {
      content_digest: digest,
      content: versioned_content,
      object_key: object_key,
    }
    definition.save!
    definition
  end

  protected

  # prepare form for publication
  def process_content(definition, raw_content)
    doc = Nokogiri::HTML5(raw_content)

    forms = doc.css('form')
    raise 'expected one form' unless forms.one?

    form = forms.first
    form.add_child(%(<input type="hidden" name="form_content_digest" value="#{definition.content_digest}">))
    protected_definition_id = ProtectedId::Encoder.encode(definition.id)
    form.add_child(%(<input type="hidden" name="form_definition_id" value="#{protected_definition_id}">))

    doc.xpath('//comment()').each(&:remove)
    doc.to_html
  end

  def upload_to_s3(definition)
    # TBD upload_to_s3, return location
    # puts content
  end
end
