###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'nokogiri'

# render and upload static forms
# PublishStaticFormsJob.new.perform('tchc/prevention_screening')
class HmisExternalApis::PublishStaticFormsJob
  include SafeInspectable

  def perform(page_name)
    renderer = HmisExternalApis::StaticPagesController.renderer.new
    form_definition = read_form_definition(page_name)
    content = renderer.render("hmis_external_apis/static_pages/form", assigns: { form_definition: form_definition})

    content_version = key_content(content)
    form = HmisExternalApis::StaticPages::Form.where(name: page_name, content_version: content_version).first_or_initialize
    # skip if already published this content
    return if form.object_key

    versioned_content = process_content(content: content, version: content_version, page_name: page_name, form_action: lambda_url)
    object_key = upload_to_s3(content: versioned_content, page_name: page_name)

    form.attributes = { object_key: object_key, form_definition: form_definition, content: versioned_content }
    form.save!
  end

  # prepare form for publication
  def process_content(content:, page_name:, version:, form_action:)
    doc = Nokogiri::HTML(content)

    forms = doc.css('form')
    raise 'expected one form' unless forms.one?

    form = forms.first
    form['action'] = form_action if form_action

    form.add_child(%(<input type="hidden" name="form_version" value="#{version}">))
    form.add_child(%(<input type="hidden" name="form_name" value="#{page_name}">))

    doc.xpath('//comment()').each(&:remove)
    doc.to_html
  end

  def lambda_url
    # TBD form action to submit to lambda
    nil
  end

  def upload_to_s3(content:, page_name:)
    # TBD upload_to_s3, return location
    # puts content
  end

  def key_content(content)
    Digest::MD5.hexdigest(content)
  end

  SUB_DIR = "drivers/hmis_external_apis/lib/static_page_forms".freeze
  def read_form_definition(page_name)
    filename = Rails.root.join("#{SUB_DIR}/#{page_name}.json")
    JSON.parse(File.read(filename))
  end
end
