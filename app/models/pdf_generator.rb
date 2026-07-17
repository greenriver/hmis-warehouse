###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class PdfGenerator
  LETTER_WIDTH_IN = 8.5
  LETTER_HEIGHT_IN = 11
  MARGIN_IN = { top: 0.5, bottom: 0.5, left: 0.4, right: 0.4 }.freeze
  CSS_PX_PER_IN = 96

  # The printable content width, in CSS pixels, for the page format/margins above.
  PRINTABLE_WIDTH_PX = ((LETTER_WIDTH_IN - MARGIN_IN[:left] - MARGIN_IN[:right]) * CSS_PX_PER_IN).floor
  # The printable content height, approximately one page's height in pixels.
  PRINTABLE_HEIGHT_PX = (LETTER_HEIGHT_IN * CSS_PX_PER_IN).floor

  # Viewport for HTML whose own JavaScript measures its content against what will be
  # printed — set this as the Puppeteer viewport so in-page measurements match what
  # Chromium actually uses when it lays out the page for print.
  MEASUREMENT_VIEWPORT = { width: PRINTABLE_WIDTH_PX, height: PRINTABLE_HEIGHT_PX }.freeze

  def perform(html:, file_name: 'output', options: {}, pdf_data: nil)
    pdf_data ||= render_pdf(html, options: options)
    Dir.mktmpdir do |dir|
      safe_name = file_name.gsub(/[^- a-z0-9]+/i, ' ').slice(0, 50).strip
      file_path = "#{dir}/#{safe_name}.pdf"
      File.open(file_path, 'wb') { |file| file.write(pdf_data) }
      yield(Pathname.new(file_path).open)
    end
    true
  end

  def self.render_pdf(...)
    new.render_pdf(...)
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
        top: "#{MARGIN_IN[:top]}in",
        bottom: "#{MARGIN_IN[:bottom]}in",
        left: "#{MARGIN_IN[:left]}in",
        right: "#{MARGIN_IN[:right]}in",
      },
      debug: {
        # headless: false,
        # devtools: true
      },
    }.
      deep_merge(options)
    Grover.new(html, **grover_options).to_pdf
  end

  def root_url
    Rails.application.routes.url_helpers.root_url(host: ENV['FQDN'])
  end

  def self.warden_proxy(user)
    Warden::Proxy.new({}, Warden::Manager.new({})).tap do |i|
      i.set_user(user, scope: :user, store: false, run_callbacks: false)
    end
  end

  def self.html(controller:, user:, template: nil, layout: false, assigns:, partial: nil)
    ActionController::Renderer::RACK_KEY_TRANSLATION['warden'] ||= 'warden'
    renderer = controller.renderer.new(
      'warden' => warden_proxy(user),
    )
    if partial.present?
      renderer.render(
        partial: partial,
        assigns: assigns,
      )
    else
      renderer.render(
        template,
        layout: layout,
        assigns: assigns,
      )
    end
  end

  # A helper method to wrap up some weirdness of Pdfunite needing a block if the objects aren't file paths
  # Pdfunite requires files to be merged thusly: Pdfunite.join(['path/file_1.pdf', 'path/file_2.pdf'])
  # and inline objects to be merged thusly: Pdfunite.join([pdf_1, pdf_2]) { |pdf| pdf }
  # If you we end up needing to do something fancy in the block, we can extend this further, but keeping the two methods
  # will enforce some standardization
  # @param [Array] pdf_objects An array of binary inline versions of the PDFs such as you get by reading a PDF file or
  # calling .to_pdf on a Grover object.
  # @return [String] string representation of a PDF object
  def self.merge_inline_pdfs(pdf_objects)
    Pdfunite.join(pdf_objects) { |pdf| pdf }
  end

  # @param [Array] files An array of paths to PDF files.
  # @return [String] string representation of a PDF object
  def self.merge_pdf_files(files)
    Pdfunite.join(files)
  end
end
