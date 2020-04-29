# This is a way to have assets in the asset pipeline that are
# different per environment

class SerializedAsset
  # These are the possible serialized things.
  # e.g. If LOGO and LOGO_CONTENT are in the environment, then the logic of
  # this class will be triggered
  IMAGES = ['LOGO', 'PRINT_LOGO', 'CAREPLAN_LOGO'].freeze

  # Change this to expire all images. If you update an image, it's fine to just
  # change this for all deployments.
  VERSION = 'v1'.freeze

  def self.paths
    @paths ||= {}
  end

  def self.init
    FileUtils.mkdir_p('public/theme/logo')

    IMAGES.each do |key|
      content_key = key + '_CONTENT'
      content_ext = key + '_EXT'
      extension = ENV.fetch(content_ext) { 'svg' }

      next unless ENV[key].present? && ENV[content_key].present?

      logo_content = Base64.decode64(ENV[content_key])

      next unless logo_content.present?

      view_path = "/theme/logo/#{ENV[key]}.#{VERSION}.#{extension}"
      path = "public#{view_path}"
      File.write(path, logo_content)

      paths[ENV[key]] = OpenStruct.new(src: view_path, server_path: path)
    end
  end

  def self.get_src(name)
    paths[name]&.src
  end

  def self.get_content(name)
    File.read(paths[name]&.server_path, 'ascii-8bit')
  end

  def self.exists?(name)
    paths[name].present?
  end
end
