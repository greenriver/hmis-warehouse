###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class PdfGenerator
  def perform(html_string)
    chrome = `which chromium-browser`.strip.presence
    Dir.mktmpdir do |dir|
      File.open("#{dir}/in.html", 'w') { |f| f.write(html_string) }
      script_path = Rails.root.join('./bin/pdf.js')
      file_url = "file://#{dir}/in.html"
      output_path = "#{dir}/out.pdf"
      stdout, stderr, status = Open3.capture3(
        'node', script_path.to_s, file_url.shellescape, output_path, chrome.to_s
      )
      raise "error #{status.inspect} while loading #{file_url}: #{stdout} #{stderr}" if stdout.present? || stderr.present? || status.to_i != 0

      yield(Pathname.new(output_path).open)
    end
  end
end
