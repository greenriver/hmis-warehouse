###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'net/http'

module AssetHelper
  ASSET_URL_REGEX = /url\(['"]?([^'"]+?)['"]?\)/

  def self.add_extension(filename, extension)
    filename.to_s.split('.').include?(extension) ? filename : "#{filename}.#{extension}"
  end

  def self.wicked_pdf_asset_base64(path)
    asset = find_asset(path)
    raise "Could not find asset '#{path}'" if asset.nil?

    base64 = Base64.encode64(asset.to_s).gsub(/\s+/, '')
    "data:#{asset.content_type};base64,#{Rack::Utils.escape(base64)}"
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
      if Regexp.last_match[1].starts_with?('data:')
        "url(#{Regexp.last_match[1]})"
      else
        "url(#{wicked_pdf_asset_path(Regexp.last_match[1])})"
      end
    end.html_safe
  end

  def self.wicked_pdf_image_tag(img, options = {})
    image_tag wicked_pdf_asset_path(img), options
  end

  def self.wicked_pdf_javascript_src_tag(jsfile, options = {})
    jsfile = add_extension(jsfile, 'js')
    ApplicationController.helpers.javascript_include_tag wicked_pdf_asset_path(jsfile), options
  end

  def self.wicked_pdf_javascript_include_tag(*sources)
    sources.collect do |source|
      source = add_extension(source, 'js')
      "<script type='text/javascript'>#{read_asset(source)}</script>"
    end.join("\n").html_safe
  end

  def self.inline_js_for_es_build(sources)
    content = sources.map do |source|
      # In deployed environments the asset gets a fancy cache busting hash appended
      # so we need to take that into account before reading it
      if Rails.env.development?
        find_asset(add_extension(source, 'js')).to_s
      else
        path = File.join(Rails.public_path, ActionController::Base.helpers.compute_asset_path(add_extension(source, 'js')))
        IO.read(path)
      end
    end.join("\n")
    "<script type='text/javascript'>#{content}</script>".html_safe
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
    if precompiled_or_absolute_asset?(source)
      asset = ApplicationController.helpers.asset_path(source)
      pathname = prepend_protocol(asset)
      if pathname =~ URI_REGEXP
        # asset_path returns an absolute URL using asset_host if asset_host is set
        pathname
      else
        File.join(Rails.public_path, asset.sub(/\A#{Rails.application.config.action_controller.relative_url_root}/, ''))
      end
    else
      asset = find_asset(source)
      if asset
        # older versions need pathname, Sprockets 4 supports only filename
        asset.respond_to?(:filename) ? asset.filename : asset.pathname
      else
        File.join(Rails.public_path, source)
      end
    end
  end

  def self.find_asset(path)
    Rails.application.assets.find_asset(path, base_path: Rails.application.root.to_s)
  end

  # will prepend a http or default_protocol to a protocol relative URL
  # or when no protcol is set.
  def self.prepend_protocol(source)
    protocol = 'https'
    if source[0, 2] == '//'
      source = [protocol, ':', source].join
    elsif source[0] != '/' && !source[0, 8].include?('://')
      source = [protocol, '://', source].join
    end
    source
  end

  def self.precompiled_or_absolute_asset?(source)
    !Rails.configuration.respond_to?(:assets) ||
      Rails.configuration.assets.compile == false ||
      source.to_s[0] == '/' ||
      source.to_s.match(/\Ahttps?\:\/\//)
  end

  def self.read_asset(source)
    if precompiled_or_absolute_asset?(source)
      pathname = asset_pathname(source)
      if pathname =~ URI_REGEXP
        read_from_uri(pathname)
      elsif File.file?(pathname)
        IO.read(pathname)
      end
    else
      find_asset(source).to_s
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
