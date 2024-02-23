require 'nokogiri'

# render and upload static forms
class HmisExternalApis::TcHmis::PublishStaticFormsJob
  def perform
    renderer = HmisExternalApis::TcHmis::StaticPagesController.renderer.new

    # form pages to publish
    page_names = [
      'tchc_helpline',
      'tchc_prevention_screening',
    ]
    page_names.each do |page_name|
      form_fields = []
      content = renderer.render("hmis_external_apis/tc_hmis/static_pages/#{page_name}", local_assigns: { field_collection: form_fields })

      # raise for now but in future we could support info pages that have no forms
      raise if form_fields.empty? || content.empty?

      version = key_content(content)
      form = HmisExternalApis::TcHmis::StaticPages::Form.where(page_name: page_name, version: version).first_or_initialize
      # skip if already published this content
      next if form.remote_location

      versioned_content = inject_version(content: content, version: version, form_action: lambda_url)
      location = upload_to_s3(content: versioned_content, page_name: page_name)

      form.update!(remote_location: location, fields: fields, page_name: page_name)
    end
  end

  # prepare form for publication
  def inject_version(content:, page_name:, form_version:, form_action:)
    doc = Nokogiri::HTML(content)

    forms = doc.css('form')
    raise 'expected one form' unless forms.one?

    form = forms.first
    form['action'] = form_action

    Nokogiri::XML::Node.new('input', doc).tap do |input|
      input['type'] = 'hidden'
      input['name'] = 'form_version'
      input['value'] = form_version
      form.add_child(input)
    end

    Nokogiri::XML::Node.new('input', doc).tap do |input|
      input['type'] = 'hidden'
      input['name'] = 'form_name'
      input['value'] = page_name
      form.add_child(input)
    end

    doc.to_html
  end

  def lambda_url
    # TBD form action to submit to lambda
  end

  def upload_to_s3(content:, page_name:)
    # TBD upload_to_s3, return location
  end

  def key_content(content)
    Digest::MD5.file(content).hexdigest
  end
end
