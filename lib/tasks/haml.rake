# frozen_string_literal: true

namespace :haml do
  desc 'Scan HAML files for potential XSS vulnerabilities in JavaScript blocks'
  task :xss_scanner do
    require_relative '../haml_js_xss_scanner'

    scanner = HamlJsXssScanner.new(ci_mode: true)
    scanner.scan
  end
end
