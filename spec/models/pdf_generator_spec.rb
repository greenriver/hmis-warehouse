# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PdfGenerator, type: :model do
  describe '.render_pdf' do
    it 'generates a PDF from a simple HTML string' do
      html = '<html><body><h1>Hello World</h1></body></html>'
      pdf_data = PdfGenerator.render_pdf(html)

      expect(pdf_data).to be_a(String)
      expect(pdf_data).to start_with('%PDF-')
      # Basic PDF validation: should have at least some content and end with EOF
      expect(pdf_data.length).to be > 100
      expect(pdf_data.b).to include('%%EOF')
    end

    it 'handles complex HTML with CSS' do
      html = <<~HTML
        <html>
          <head>
            <style>
              h1 { color: red; font-size: 40px; }
              .page-break { page-break-after: always; }
            </style>
          </head>
          <body>
            <h1>Page 1</h1>
            <div class="page-break"></div>
            <h1>Page 2</h1>
          </body>
        </html>
      HTML
      pdf_data = PdfGenerator.render_pdf(html)

      expect(pdf_data).to be_a(String)
      expect(pdf_data).to start_with('%PDF-')
    end
  end

  describe '#perform' do
    it 'yields a file handle to a temporary PDF file' do
      html = '<html><body><h1>Test Output</h1></body></html>'
      file_name = 'my_test_pdf'

      yielded = false
      PdfGenerator.new.perform(html: html, file_name: file_name) do |file|
        yielded = true
        expect(file).to be_a(File)
        expect(File.basename(file.path)).to match(/my test pdf\.pdf/) # PdfGenerator replaces non-alphanumeric with spaces
        expect(file.read).to start_with('%PDF-')
      end

      expect(yielded).to be true
    end
  end

  describe '.merge_inline_pdfs' do
    it 'merges multiple PDF strings into one' do
      html1 = '<html><body><h1>Doc 1</h1></body></html>'
      html2 = '<html><body><h1>Doc 2</h1></body></html>'
      pdf1 = PdfGenerator.render_pdf(html1)
      pdf2 = PdfGenerator.render_pdf(html2)

      merged_pdf = PdfGenerator.merge_inline_pdfs([pdf1, pdf2])

      expect(merged_pdf).to be_a(String)
      expect(merged_pdf).to start_with('%PDF-')
      expect(merged_pdf.length).to be > pdf1.length
    end
  end
end
