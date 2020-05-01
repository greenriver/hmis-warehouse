Rails.logger.debug "Running initializer in #{__FILE__}"

if ENV['WKHTMLTOPDF_PATH'].present?
  WickedPdf.config = {
    exe_path: '/usr/bin/wkhtmltopdf'
  }
end
