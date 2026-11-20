###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'net/http'

module AssetHelper
  ASSET_URL_REGEX = /url\(['"]?([^'"]+?)['"]?\)/

  def self.add_extension(filename, extension)
    filename.to_s.split('.').include?(extension) ? filename : "#{filename}.#{extension}"
  end

  def self.wicked_pdf_asset_base64(path)
    content = asset_content(path)
    raise "Could not find asset '#{path}'" if content.nil?

    base64 = Base64.strict_encode64(content)
    "data:#{Rack::Mime.mime_type(File.extname(path))};base64,#{Rack::Utils.escape(base64)}"
  end

  # Using `image_tag` with URLs when generating PDFs (specifically large PDFs with lots of pages) can cause buffer/stack overflows.
  #
  def self.wicked_pdf_url_base64(url)
    response = Net::HTTP.get_response(URI(url))

    if response.is_a?(Net::HTTPSuccess)
      base64 = Base64.encode64(response.body).gsub(/\s+/, '')
      "data:#{response.content_type};base64,#{Rack::Utils.escape(base64)}"
    else
      Rails.logger.warn("[wicked_pdf] #{response.code} #{response.message}: #{url}")
      nil
    end
  end

  def self.wicked_pdf_stylesheet_link_tag(*sources)
    stylesheet_contents = sources.collect do |source|
      source = add_extension(source, 'css')
      "<style type='text/css'>#{read_asset(source)}</style>"
    end.join("\n")

    stylesheet_contents.gsub(ASSET_URL_REGEX) do
      # A url(#id) points at an element in the document, not at a file.
      if Regexp.last_match[1].starts_with?('data:', '#')
        "url(#{Regexp.last_match[1]})"
      else
        "url(#{wicked_pdf_asset_path(Regexp.last_match[1])})"
      end
    end.html_safe
  end

  def self.wicked_pdf_javascript_include_tag(*sources)
    sources.collect do |source|
      source = add_extension(source, 'js')
      "<script type='text/javascript'>#{read_asset(source)}</script>"
    end.join("\n").html_safe
  end

  def self.wicked_pdf_asset_path(asset)
    if (pathname = asset_pathname(asset).to_s) =~ URI_REGEXP
      pathname
    else
      "file:///#{pathname}"
    end
  end

  # borrowed from actionpack/lib/action_view/helpers/asset_url_helper.rb
  URI_REGEXP = /^[-a-z]+:\/\/|^(?:cid|data):|^\/\//

  def self.asset_pathname(source)
    if absolute_source?(source)
      asset = ApplicationController.helpers.asset_path(source)
      pathname = prepend_protocol(asset)
      if pathname =~ URI_REGEXP
        # asset_path returns an absolute URL using asset_host if asset_host is set
        pathname
      else
        File.join(Rails.public_path, asset.sub(/\A#{Rails.application.config.action_controller.relative_url_root}/, ''))
      end
    else
      precompiled = precompiled_path(source)
      return precompiled if precompiled

      compiled_asset(source)&.filename || File.join(Rails.public_path, source)
    end
  end

  def self.find_asset(path)
    Rails.application.assets.find_asset(path, base_path: Rails.application.root.to_s)
  end

  # Outside development and test, assets are read from the precompiled files so that
  # web processes don't compile them. Compiling is the fallback for an asset missing
  # from the manifest, and only works where assets.compile is on.
  def self.asset_content(source)
    precompiled = precompiled_path(source)
    return File.read(precompiled) if precompiled

    compiled_asset(source)&.to_s
  end

  def self.digest_path(source)
    return find_asset(source)&.digest_path if running_in_development?

    Rails.application.assets_manifest.assets[source] || compiled_asset(source)&.digest_path
  end

  def self.precompiled_path(source)
    return if running_in_development?

    manifest = Rails.application.assets_manifest
    digest_path = manifest.assets[source]
    File.join(manifest.directory, digest_path) if digest_path
  end

  def self.compiled_asset(source)
    raise Sprockets::Rails::Helper::AssetNotFound, "The asset \"#{source}\" is not precompiled" if Rails.application.assets.nil?

    find_asset(source)
  end

  # will prepend a http or default_protocol to a protocol relative URL
  # or when no protocol is set.
  def self.prepend_protocol(source)
    protocol = 'https'
    if source[0, 2] == '//'
      source = [protocol, ':', source].join
    elsif source[0] != '/' && !source[0, 8].include?('://')
      source = [protocol, '://', source].join
    end
    source
  end

  def self.absolute_source?(source)
    source.to_s[0] == '/' || source.to_s.match?(/\Ahttps?:\/\//)
  end

  def self.read_asset(source)
    return asset_content(source) unless absolute_source?(source)

    pathname = asset_pathname(source)
    if pathname =~ URI_REGEXP
      read_from_uri(pathname)
    elsif File.file?(pathname)
      File.read(pathname)
    end
  end

  def self.read_from_uri(uri)
    asset = Net::HTTP.get(URI(uri))
    asset&.force_encoding('UTF-8')
    # asset = gzip(asset) if WickedPdf.config[:expect_gzipped_remote_assets]
    asset
  end

  # def self.gzip(asset)
  #   stringified_asset = StringIO.new(asset)
  #   gzipper = Zlib::GzipReader.new(stringified_asset)
  #   gzipper.read
  # rescue Zlib::GzipFile::Error
  #   nil
  # end

  def self.running_in_development?
    Rails.env.development? || Rails.env.test?
  end
end
