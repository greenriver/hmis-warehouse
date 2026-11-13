###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.feature 'HUD report PDF auto-scale script', type: :rails_system do
  include_context 'RailsSystemHelper'

  # Read directly from the real asset file (not hand-copied) so this test can never
  # drift from what app/assets/javascripts/hud_report_pdf_autoscale.js actually ships.
  let(:script) { Rails.root.join('app/assets/javascripts/hud_report_pdf_autoscale.js').read }

  it 'shrinks an over-wide table to fit its container and leaves a narrow table alone', js: true do
    # Container is the real printable width (PdfGenerator::PRINTABLE_WIDTH_PX), not an
    # arbitrary placeholder. The "wide" table is 5x that and tall enough for many rows —
    # comparable to a real report table significantly exceeding the printable width, not
    # a token amount of overflow.
    container_width = PdfGenerator::PRINTABLE_WIDTH_PX
    wide_table_width = container_width * 5
    wide_table_height = 1500 # e.g. several dozen data rows
    narrow_table_width = 400 # comfortably narrower than the container

    fixture_html = <<~HTML
      <!DOCTYPE html>
      <html>
        <body>
          <div class="summary-tables">
            <div class="table-responsive" style="width: #{container_width}px; overflow: auto;">
              <table style="width: #{wide_table_width}px; height: #{wide_table_height}px; border-collapse: collapse; border-spacing: 0;">
                <tr><td style="height: #{wide_table_height}px; padding: 0; border: 0;">wide</td></tr>
              </table>
            </div>
            <div class="table-responsive" style="width: #{container_width}px; overflow: auto;">
              <table style="width: #{narrow_table_width}px; border-collapse: collapse; border-spacing: 0;">
                <tr><td style="padding: 0; border: 0;">narrow</td></tr>
              </table>
            </div>
          </div>
          <script>#{script}</script>
        </body>
      </html>
    HTML

    file = Tempfile.new(['hud_report_autoscale_fixture', '.html'])
    file.write(fixture_html)
    file.close

    begin
      visit("file://#{file.path}")

      wide_width = page.evaluate_script(
        "document.querySelectorAll('.table-responsive')[0].querySelector('table').getBoundingClientRect().width",
      )
      narrow_width = page.evaluate_script(
        "document.querySelectorAll('.table-responsive')[1].querySelector('table').getBoundingClientRect().width",
      )
      wide_container_height = page.evaluate_script(
        "document.querySelectorAll('.table-responsive')[0].getBoundingClientRect().height",
      )

      # Wide table shrinks to exactly fit its container.
      expect(wide_width).to eq(container_width.to_f)
      # Narrow table is left at its natural size.
      expect(narrow_width).to eq(narrow_table_width.to_f)
      # Wide table container height is reduced to match the zoomed table's height
      # (scale factor is container_width / wide_table_width = 1/5).
      expect(wide_container_height).to eq(wide_table_height / 5.0)
    ensure
      file.unlink
    end
  end
end
