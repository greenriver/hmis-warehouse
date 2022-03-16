###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
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
      # header_template: '<h2>Header</h2>',
      # footer_template: '<h6 class="text-center"><span class="pageNumber"></span> of <span class="totalPages"></span></h6>',
      timeout: 600_000, # Stop after 10 minutes
      request_timeout: 600_000, # Stop after 10 minutes
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
    }.
      deep_merge(options)
    Grover.new(html, grover_options).to_pdf
  end

  def root_url
    Rails.application.routes.url_helpers.root_url(host: ENV['FQDN'])
  end

  def self.warden_proxy(user)
    Warden::Proxy.new({}, Warden::Manager.new({})).tap do |i|
      i.set_user(user, scope: :user, store: false, run_callbacks: false)
    end
  end

  def self.html(controller:, template:, layout:, user:, assigns:)
    ActionController::Renderer::RACK_KEY_TRANSLATION['warden'] ||= 'warden'
    renderer = controller.renderer.new(
      'warden' => warden_proxy(user),
    )
    renderer.render(
      template,
      layout: layout,
      assigns: assigns,
    )
  end
end
