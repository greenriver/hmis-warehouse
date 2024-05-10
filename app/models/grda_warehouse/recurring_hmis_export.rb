###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'pty'
require 'expect'
module GrdaWarehouse
  class RecurringHmisExport < GrdaWarehouseBase
    attr_accessor :version

    attr_encrypted :s3_access_key_id, key: ENV['ENCRYPTION_KEY'][0..31]
    attr_encrypted :s3_secret_access_key, key: ENV['ENCRYPTION_KEY'][0..31], attribute: 'encrypted_s3_secret'
    attr_encrypted :zip_password, key: ENV['ENCRYPTION_KEY'][0..31]

    acts_as_paranoid

    has_many :recurring_hmis_export_links
    has_many :hmis_exports, through: :recurring_hmis_export_links

    def should_run?
      if hmis_exports.exists?
        last_export_finished_on = recurring_hmis_export_links.maximum(:exported_at)
        return Date.current - last_export_finished_on >= every_n_days
      end
      # Don't re-run the export on the day it was requested
      ! updated_at.today?
    end

    def run
      filter = ::Filters::HmisExport.new(filter_hash)
      filter.adjust_reporting_period
      filter.schedule_job(report_url: nil)
    end

    def s3_present?
      s3_region.present? && s3_bucket.present?
    end

    def s3_valid?
      return aws_s3.present?
    end

    def store(report)
      content = encrypt_zip(report.content)
      aws_s3.store(content: content, name: object_name(report)) if s3_valid?
    end

    # Temporarily replace the content of the report with a password protected zip
    # which can be sent to S3
    private def encrypt_zip(content)
      return content unless zip_password.present?

      case encryption_type
      when 'zip'
        encrypt_zipcloak(content)
      when '7z'
        encrypt_seven_zip(content)
      end
    end

    private def encrypt_zipcloak(content)
      tmp = Tempfile.new(['hmis_export', '.zip'], Rails.root.join('tmp').to_s, binmode: true)
      source_path = Rails.root.join(tmp.path).to_s
      export_dir = ::File.dirname(source_path)
      destination_path = "#{::File.join(export_dir, ::File.basename(source_path, '.zip'))}_enc.zip"
      tmp.write(content)
      tmp.close

      Tempfile.create('expect', export_dir.to_s) do |expect_script|
        expect_content = <<~EXPECT
          #!/usr/bin/expect -f

          set force_conservative 0  ;# set to 1 to force conservative mode even if
                                    ;# script wasn't run conservatively originally
          if {$force_conservative} {
            set send_slow {1 .1}
            proc send {ignore arg} {
              sleep .1
              exp_send -s -- $arg
            }
          }

          set timeout -1
          spawn zipcloak --output-file #{destination_path} #{source_path}
          match_max 100000
          expect -exact "Enter password: "
          send -- "#{zip_password}\r"
          expect -exact "\r
          Verify password: "
          send -- "#{zip_password}\r"
          expect eof

          send_user "\n $expect_out(buffer) \n"
        EXPECT
        expect_script.write(expect_content)
        expect_script.close
        FileUtils.chmod(0o770, expect_script.path)
        system(expect_script.path)
      end

      # return the encrypted content
      encrypted_content = ::File.open(destination_path, binmode: true).read
      FileUtils.rm(destination_path)
      tmp.unlink
      encrypted_content
    end

    # Write out the zip file
    # expand the zip file
    # re-compress the zip file with a password and 7zip
    private def encrypt_seven_zip(content)
      tmp = Tempfile.new(['hmis_export', '.zip'], 'tmp', binmode: true)
      # local_source_path = tmp.path
      source_path = Rails.root.join(tmp.path).to_s
      destination_path = ::File.join(::File.dirname(source_path), ::File.basename(source_path, '.zip')).to_s
      # local_destination_path = ::File.join(::File.dirname(local_source_path), ::File.basename(source_path, '.zip')).to_s
      destination_file = "#{::File.join(::File.dirname(source_path), ::File.basename(source_path, '.zip'))}_enc.7z"
      tmp.write(content)
      tmp.close

      FileUtils.mkdir(destination_path) unless ::File.exist?(destination_path)
      Zip::File.open(source_path) do |zipped_file|
        zipped_file.each do |entry|
          entry.extract(::File.join(destination_path, ::File.basename(entry.name)))
        end
      end

      cmd = "7z a -mx9 -p#{zip_password} #{destination_file} #{destination_path}/*.csv"
      system(cmd)

      # ::File.open(destination_file, 'wb') do |file|
      #   SevenZipRuby::SevenZipWriter.open(file, password: zip_password) do |szw|
      #     szw.method = 'LZMA'
      #     szw.level = 9
      #     szw.solid = false
      #     szw.header_compression = false
      #     szw.header_encryption = true
      #     # szw.multi_threading = false
      #     Dir.glob("#{destination_path}/*.csv").each do |f|
      #       szw.add_data(::File.open(::File.join(local_destination_path, ::File.basename(f))).read, ::File.basename(f))
      #     end
      #   end
      # end
      # for some reason we need a bit of sand after talking to zipcloak
      sleep(5) unless ::File.exist?(destination_file)
      # return the encrypted content
      encrypted_content = ::File.open(destination_file, binmode: true).read
      FileUtils.rm_rf(destination_path)
      FileUtils.rm(destination_file)
      tmp.unlink
      encrypted_content
    end

    def object_name(report)
      prefix = ''
      prefix = "#{s3_prefix.strip}-" if s3_prefix.present?
      date = Date.current.strftime('%Y%m%d')
      ext = encryption_type.presence || 'zip'
      "#{prefix}#{date}-#{report.export_id}.#{ext}"
    end

    def self.available_reporting_ranges
      {
        'Dates specified above': 'fixed',
        '(n) days before run date': 'n_days',
        'Month prior to run date': 'month',
        'Year prior to run date': 'year',
      }
    end

    def self.available_encryption_types
      {
        'Standard zip file (.zip)' => nil,
        'Encrypted zip file (.zip)' => 'zip',
        'Encrypted 7zip file (.7z)' => '7z',
      }
    end

    validates :reporting_range, inclusion: { in: available_reporting_ranges.values }

    def aws_s3
      return nil unless s3_present?

      @aws_s3 ||= if s3_secret_access_key.present?
        AwsS3.new(
          region: s3_region.strip,
          bucket_name: s3_bucket.strip,
          access_key_id: s3_access_key_id.strip,
          secret_access_key: s3_secret_access_key,
        )
      else
        AwsS3.new(
          region: s3_region.strip,
          bucket_name: s3_bucket.strip,
        )
      end
    end

    def self.available_s3_regions
      [
        'us-east-1',
        'us-east-2',
        'us-west-1',
        'us-west-2',
        'ap-northeast-1',
        'ap-northeast-2',
        'ap-south-1',
        'ap-southeast-1',
        'ap-southeast-2',
        'ca-central-1',
        'eu-central-1',
        'eu-west-1',
        'eu-west-2',
        'eu-west-3',
        'sa-east-1',
      ]
    end

    def filter_hash
      hash = options
      hash[:reporting_range] = reporting_range
      hash[:reporting_range_days] = reporting_range_days
      hash[:recurring_hmis_export_id] = id
      hash[:version] ||= '2024' # FIXME, this should pull from the active version
      hash[:user_id] = user_id
      return hash
    end
  end
end
