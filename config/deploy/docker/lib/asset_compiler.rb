require_relative 'aws_sdk_helpers'
require 'byebug'

class AssetCompiler
  include AwsSdkHelpers::Helpers

  THEME_ASSETS_BUCKET = 'openpath-ecs-assets'.freeze
  COMPILED_ASSETS_BUCKET = 'openpath-precompiled-assets'.freeze

  def initialize(*args)
    @target_group_name = args[0][:target_group_name]
    @secret_arn = args[0][:secrets_arn]
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

  def run!
    time_me name: 'Secrets download' do
      system(`SECRET_ARN=#{@secret_arn} bin/download_secrets.rb > .env`)
    end

    Dotenv.load('.env', '.env.local')

    time_me name: 'Clobberin\'' do
      system('source .env; rake assets:clobber') # TODO: don't call out to bundle like this, it's inefficient
    end

    checksum = '<nochecksum>'
    time_me name: 'Checksumming' do
      checksum = `SECRET_ARN=#{@secret_arn} ASSETS_PREFIX=#{@target_group_name} bin/asset_checksum`.split(' ')[-1]
    end

    puts "Asset checksum: [#{checksum}]"

    existing_assets = ''
    time_me name: 'Checking if compiled assets already exist' do
      existing_assets = `aws s3 ls #{COMPILED_ASSETS_BUCKET}/#{@target_group_name}/#{checksum}`.strip
    end

    unless existing_assets.empty?
      puts 'Compiled assets already exist.'
      return
    end

    time_me name: 'Compiling assets' do
      system('source .env; rake --quiet assets:precompile >/dev/null') # TODO: don't call out to bundle like this, it's inefficient
    end

    time_me name: 'Uploading compiled assets' do
      system("aws s3 cp --recursive public/assets s3://#{COMPILED_ASSETS_BUCKET}/#{@target_group_name}/#{checksum} >/dev/null")
    end
  end
end
