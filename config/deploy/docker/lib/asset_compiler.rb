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

  def run!
    t1 = Time.now
    system(`SECRET_ARN=#{@secret_arn} bin/download_secrets.rb > .env`)
    t2 = Time.now
    puts "Secrets fetching took #{t2 - t1}"

    Dotenv.load('.env', '.env.local')

    t1 = Time.now
    `rake assets:clobber` # TODO: don't call out to bundle like this, it's inefficient
    t2 = Time.now
    puts "Clobbering took #{t2 - t1}"

    t1 = Time.now
    checksum = `SECRET_ARN=#{@secret_arn} ASSETS_PREFIX=#{@target_group_name} bin/asset_checksum`.split(' ')[-1]
    t2 = Time.now
    puts "Checksumming took #{t2 - t1}"

    puts checksum

    t1 = Time.now
    existing_assets = `aws s3 ls #{COMPILED_ASSETS_BUCKET}/#{@target_group_name}/#{checksum}`.strip
    t2 = Time.now
    puts "Checking for existing assets took #{t2 - t1}"

    return unless existing_assets.empty?

    t1 = Time.now
    `rake assets:precompile` # TODO: don't call out to bundle like this, it's inefficient
    t2 = Time.now
    puts "Precompiling took #{t2 - t1}"

    t1 = Time.now
    system("aws s3 cp --recursive public/assets s3://#{COMPILED_ASSETS_BUCKET}/#{@target_group_name}/#{checksum} >/dev/null")
    t2 = Time.now
    puts "Uploading assets took #{t2 - t1}"
  end
end
