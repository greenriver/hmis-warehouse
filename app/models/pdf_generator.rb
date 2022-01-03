###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class PdfGenerator
  def perform(html:, file_name: 'output', options: {})
    pdf_data = render_pdf(html, options: options)
    Dir.mktmpdir do |dir|
      safe_name = file_name.gsub(/[^- a-z0-9]+/i, ' ').slice(0, 50).strip
      file_path = "#{dir}/#{safe_name}.pdf"
      File.open(file_path, 'wb') { |file| file.write(pdf_data) }
      yield(Pathname.new(file_path).open)
    end
    true
  end

  def render_pdf(html, options: {})
    grover_options = {
      display_url: root_url,
      display_header_footer: false,
      header_template: '<h2>Header</h2>',
      footer_template: '<h6 class="text-center">Footer</h6>',
      timeout: 150_000,
      format: 'Letter',
      emulate_media: 'print',
      margin: {
        top: '.5in',
        bottom: '.5in',
        left: '.4in',
        right: '.4in',
      },
      debug: {
        # headless: false,
        # devtools: true
      },
    }.deep_merge(options)
    Grover.new(html, grover_options).to_pdf
  end

  def root_url
    Rails.application.routes.url_helpers.root_url(host: ENV['FQDN'])
  end
end
