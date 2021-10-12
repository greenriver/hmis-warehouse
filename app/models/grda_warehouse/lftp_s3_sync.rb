###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# NOTE: Sometimes we need to fetch data to import from odd FTP servers that
# Ruby can't deal with directly, this will fetch and push to S3 for normal processing
module GrdaWarehouse
  class LftpS3Sync < GrdaWarehouseBase
    acts_as_paranoid
    attr_encrypted :ftp_pass, key: ENV['ENCRYPTION_KEY'][0..31]

    belongs_to :data_source
    has_one :hmis_import_config, primary_key: :data_source_id, foreign_key: :data_source_id

    def fetch_and_push
      ensure_tmp_destination
      set_lftp_bookmark
      set_lftp_confg

      fetch
      push

      remove_tmp_destination
      remove_lftp_bookmark
    end

    def slug
      data_source.short_name.underscore.parameterize(separator: '_')
    end

    private def lftp_bookmark
      "#{slug}	ftp://#{ftp_user}:#{ftp_pass}@#{ftp_host}/"
    end

    private def tmp_destination
      File.join('tmp', slug)
    end

    private def ensure_tmp_destination
      system("mkdir -p #{tmp_destination}")
      # FileUtils.mkdir_p(tmp_destination)
    end

    private def remove_tmp_destination
      system("rm -rf #{tmp_destination}")
      # FileUtils.rm_rf(tmp_destination)
    end

    # NOTE: If we ever have more than one of these, we'll need to be
    # more careful and not truncate the file
    private def set_lftp_bookmark
      system("mkdir -p #{lftp_bookmark_path}")
      system("echo #{lftp_bookmark} > #{lftp_bookmark_location}")
      # FileUtils.mkdir_p(lftp_bookmark_path)
      # f = File.new(lftp_bookmark_location, 'w')
      # f.write(lftp_bookmark)
      # f.close()
    end

    private def set_lftp_confg
      system("mkdir -p #{lftp_bookmark_path}")
      system("echo 'set ssl:verify-certificate no' > #{lftp_config_location}")
      system("echo 'set ftp:ssl-protect-data true' >> #{lftp_config_location}")
      system("echo 'set mirror:exclude-regex ^[\.b]+' >> #{lftp_config_location}")
    end

    private def remove_lftp_bookmark
      system("rm -rf #{lftp_bookmark_path}")
      # FileUtils.rm_rf(lftp_bookmark_path)
    end

    private def lftp_bookmark_path
      File.join('~', '.lftp')
    end

    private def lftp_bookmark_location
      File.join(lftp_bookmark_path, 'bookmarks')
    end

    private def lftp_config_location
      File.join(lftp_bookmark_path, 'rc')
    end

    def fetch
      system("lftp -c \"open #{slug}; lcd #{tmp_destination}; mirror --verbose --exclude tmp\"")
    end

    def push
      s3_missing.each do |file_name|
        full_path = File.join(tmp_destination, file_name)
        s3.put(file_name: full_path, prefix: s3_path.gsub(/\/$/, ''))
      end
    end

    private def s3_missing
      lftp_existing - s3_existing
    end

    private def s3_existing
      s3.fetch_key_list(prefix: s3_path).map{|e| e.gsub(/^#{s3_path}/, '')}
    end

    private def lftp_existing
      Dir.entries(tmp_destination).reject{|e| e.in?(['.', '..'])}
    end

    private def s3_path
      hmis_import_config.s3_path
    end

    private def s3
      @s3 ||= AwsS3.new(
        region: hmis_import_config.s3_region,
        bucket_name: hmis_import_config.s3_bucket_name,
        access_key_id: hmis_import_config.s3_access_key_id,
        secret_access_key: hmis_import_config.s3_secret_access_key,
      )
    end
  end
end
