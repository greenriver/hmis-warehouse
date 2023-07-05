###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# Example for testing:
# GrdaWarehouse::Theme.create!(
#   client: 'myclient', # should match ENV['CLIENT']
#   hmis_value: {
#     palette: {
#       primary: {
#         main: '#0D394E',
#       },
#       secondary: {
#         main: '#357650',
#       },
#     },
#   }
# )

# Notes for remote credential setup
# creds = GrdaWarehouse::RemoteCredentials::S3.where(slug: 'theme').first_or_initialize
# creds.update(
#   bucket: 'openpath-ecs-assets',
#   region: 'us-east-1',
#   s3_access_key_id: 'local_access_key',
#   s3_secret_access_key: 'local_secret_key',
#   s3_prefix: "#{ENV['CLIENT']}-warehouse-#{Rails.env}-ecs",
#   active: true,
# )
# theme = GrdaWarehouse::Theme.first_or_create(client: ENV.fetch('CLIENT'))
# theme.update(remote_credential: creds)
module GrdaWarehouse
  class Theme < GrdaWarehouseBase
    belongs_to :remote_credential, class_name: 'GrdaWarehouse::RemoteCredentials::S3', optional: true

    def set_theme_defaults
      # Fetch files from S3 if available or use defaults
      self.css_file_contents ||= css_file_contents_remote.presence || css_file_contents_default
      self.scss_file_contents ||= scss_file_contents_remote.presence || scss_file_contents_default
    end

    private def s3
      remote_credential&.s3
    end

    private def css_file_contents_remote
      return unless remote_credential
      return unless remote_css_file_exists?

      s3.get_as_io(key: remote_css_full_file_path)&.read
    end

    private def remote_css_file_exists?
      s3.fetch_key_list(prefix: remote_css_file_path).include?(remote_css_full_file_path)
    end

    private def remote_css_file_path
      "#{remote_credential.s3_prefix}/#{css_file_path}"
    end

    def css_file_path
      'app/assets/stylesheets/theme/styles'
    end

    def css_file_name
      '_variables.scss'
    end

    private def remote_css_full_file_path
      "#{remote_css_file_path}/#{css_file_name}"
    end

    def store_remote_css_file
      return unless remote_credential

      # Write the local file for dev environments
      ::File.open("#{css_file_path}/#{css_file_name}", 'w') { |f| f.write(css_file_contents) } if Rails.env.development?
      # store the S3 version
      s3.store(content: css_file_contents, name: remote_css_full_file_path)
    end

    # This happens automatically when we deploy, but for testing locally
    def fetch_remote_css_file
      s3.fetch(file_name: css_file_name, prefix: remote_css_file_path, target_path: "#{css_file_path}/#{css_file_name}")
    end

    private def css_file_contents_default
      'span {}'
    end

    private def scss_file_contents_remote
      return unless remote_credential
      return unless remote_scss_file_exists?

      s3.get_as_io(key: remote_scss_full_file_path)&.read
    end

    private def remote_scss_file_exists?
      s3.fetch_key_list(prefix: remote_scss_file_path).include?(remote_scss_full_file_path)
    end

    private def remote_scss_file_path
      "#{remote_credential.s3_prefix}/#{scss_file_path}"
    end

    def scss_file_path
      'app/assets/stylesheets/application/_custom/theme'
    end

    def scss_file_name
      "#{ENV.fetch('CLIENT', 'client')}.scss"
    end

    private def remote_scss_full_file_path
      "#{remote_scss_file_path}/#{scss_file_name}"
    end

    def store_remote_scss_file
      return unless remote_credential

      # Write the local file for dev environments
      ::File.open("#{scss_file_path}/#{scss_file_name}", 'w') { |f| f.write(scss_file_contents) } if Rails.env.development?
      # store the S3 version
      s3.store(content: scss_file_contents, name: remote_scss_full_file_path)
    end

    # This happens automatically when we deploy, but for testing locally
    def fetch_remote_scss_file
      s3.fetch(file_name: scss_file_name, prefix: remote_scss_file_path, target_path: "#{scss_file_path}/#{scss_file_name}")
    end

    private def scss_file_contents_default
      sheet = Rails.root.join('app', 'assets', 'stylesheets', 'application', '_custom', "#{ENV['CLIENT']}.scss")
      return '' unless ENV['CLIENT'].present? && ::File.exist?(sheet)

      ::File.read(sheet)
    end
  end
end
