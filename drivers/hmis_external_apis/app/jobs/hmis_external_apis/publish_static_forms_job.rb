###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'nokogiri'

# render and upload static forms
class HmisExternalApis::PublishStaticFormsJob
  include SafeInspectable

  def perform
    # form pages to publish. Maybe could use ENV['CLIENT']
    subdir = 'tchc'
    page_names(subdir).each do |page_name|
      process_page(page_name)
    end
  end

  protected

  def process_page(page_name)
    form_fields = []
    renderer = HmisExternalApis::StaticPagesController.renderer.new
    content = renderer.render("hmis_external_apis/static_pages/#{page_name}", assigns: { field_collection: form_fields })

    # raise for now but in future we could support info pages that have no forms
    raise if form_fields.empty? || content.empty?

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

  def page_names(subdir)
    dirname = Rails.root.join("drivers/hmis_external_apis/app/views/hmis_external_apis/static_pages/#{subdir}").to_s
    Dir.entries(dirname).
      # skip partial views
      filter { |file| file =~ /\A[a-z]/i ? File.file?(File.join(dirname, file)) : false }.
      map { |file| "#{subdir}/#{file}".sub(/\.[a-z0-9]+\z/i, '') }
  end
end
