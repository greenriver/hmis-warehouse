###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.feature 'HUD report PDF auto-scale script', type: :rails_system do
  let(:user) { create(:user) }
  let(:report_name) { HudApr::Generators::Apr::Fy2024::Generator.title }
  let(:report) { create(:hud_reports_report_instance, user: user, report_name: report_name, options: {}) }
  let(:rendered_html) do
    ActionController::Renderer::RACK_KEY_TRANSLATION['warden'] ||= 'warden'
    renderer = HudApr::AprsController.renderer.new(
      'warden' => PdfGenerator.warden_proxy(user),
    )
    renderer.render(
      'hud_reports/download',
      layout: 'layouts/hud_report_export',
      assigns: { report: report, generator: HudApr::Generators::Apr::Fy2024::Generator },
      formats: [:html],
    )
  end

  # Extracted from the real rendered layout (not hand-copied) so this test can never
  # drift from what layouts/hud_report_export.haml actually ships.
  let(:script) do
    match = rendered_html.match(/<script>\s*(window\.addEventListener\('load'.*?)<\/script>/m)
    raise "couldn't find auto-scale script in rendered HTML — did layouts/hud_report_export.haml change?" unless match

    match[1]
  end

  it 'shrinks an over-wide table to fit its container, compresses the reserved space, and leaves a narrow table alone', js: true do
    fixture_html = <<~HTML
      <!DOCTYPE html>
      <html>
        <body>
          <div class="summary-tables">
            <div class="table-responsive" style="width: 200px; overflow: auto;">
              <table style="width: 600px; height: 300px; border-collapse: collapse; border-spacing: 0;">
                <tr><td style="height: 300px; padding: 0; border: 0;">wide</td></tr>
              </table>
            </div>
            <div class="table-responsive" style="width: 200px; overflow: auto;">
              <table style="width: 100px; border-collapse: collapse; border-spacing: 0;">
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

      # Wide table (600px) shrinks to exactly fit its 200px container.
      expect(wide_width).to eq(200.0)
      # Narrow table (100px) is left at its natural size.
      expect(narrow_width).to eq(100.0)
      # Container height is set to naturalHeight * scale — the wide table is 300px
      # tall and scale is 200/600 (container width / table width) — so it should
      # land at exactly 300 * (200.0 / 600) = 100px.
      expect(wide_container_height).to eq(100.0)
    ensure
      file.unlink
    end
  end
end
