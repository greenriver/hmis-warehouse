require_relative 'aws_sdk_helpers'
require 'dotenv'

class AssetCompiler
  include AwsSdkHelpers::Helpers

  THEME_ASSETS_BUCKET = 'openpath-ecs-assets'.freeze
  COMPILED_ASSETS_BUCKET = 'openpath-precompiled-assets'.freeze

  def initialize(*args)
    @target_group_name = args[0][:target_group_name].gsub(/[^0-9A-Za-z\_\-]/, '') # Sanitize for cli.
    @secret_arn = args[0][:secrets_arn].gsub(/[^0-9A-Za-z\_\-\:\/]/, '') # Sanitize for cli.
  end

  def time_me(name: '<unnamed>', &block)
    if block_given?
      t1 = Time.now
      yield(block)
      t2 = Time.now
      puts "⏱ #{name} took #{t2 - t1}"
    else
      puts "where's my block >:("
    end
  end

  def self.compiled_assets_s3_path(target_group_name, checksum)
    target_group_name = target_group_name.gsub(/[^0-9A-Za-z\_\-]/, '') # Sanitize for cli.
    checksum = checksum.gsub(/[^0-9A-Za-z]/, '') # Sanitize for cli.
    File.join(COMPILED_ASSETS_BUCKET, target_group_name, checksum)
  end

  def run!
    checksum = '<nochecksum>'
    time_me name: 'Checksumming' do
      checksum = `SECRET_ARN=#{@secret_arn.shellescape} ASSETS_PREFIX=#{@target_group_name.shellescape} bin/asset_checksum`.split(' ')[-1]
    end

    puts "Asset checksum: [#{checksum}]"

    existing_assets = ''
    time_me name: 'Checking if compiled assets already exist' do
      existing_assets = `aws s3 ls #{self.class.compiled_assets_s3_path(@target_group_name, checksum).shellescape}`.strip
    end

    unless existing_assets.empty?
      puts 'Compiled assets already exist.'
      return
    end

    time_me name: 'Secrets download' do
      system(`SECRET_ARN=#{@secret_arn.shellescape} bin/download_secrets.rb > .env`)
    end

    Dotenv.load('.env')

    time_me name: 'Compiling assets' do
      system('source .env; rake --quiet assets:precompile > /dev/null 2>&1') # TODO: don't call out to rake like this, it's inefficient
    end

    time_me name: 'Uploading compiled assets' do
      system("aws s3 cp --recursive public/assets s3://#{self.class.compiled_assets_s3_path(@target_group_name, checksum).shellescape} >/dev/null")
    end
  end
end
