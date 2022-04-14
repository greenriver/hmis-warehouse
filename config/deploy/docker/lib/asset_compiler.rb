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
    system('bundle exec rake assets:clobber') # TODO: don't call out to bundle like this, it's inefficient

    system(`SECRET_ARN=#{@secret_arn} bin/download_secrets.rb > .env`)

    Dotenv.load('.env', '.env.local')

    # system('ASSETS_PREFIX=#{@target_group_name} bin/asset_checksum')
    tmp = `ASSETS_PREFIX=#{@target_group_name} bin/asset_checksum`
    checksum = tmp[-1].split(' ')
    puts tmp

    puts checksum

    existing_assets = `aws s3 ls #{COMPILED_ASSETS_BUCKET}/#{@target_group_name}/#{checksum}`.strip

    puts "aws s3 ls #{COMPILED_ASSETS_BUCKET}/***/#{checksum}"
    puts existing_assets

    return unless existing_assets.empty? || existing_assets == 'PRE []/'

    system('bundle exec rake assets:precompile') # TODO: don't call out to bundle like this, it's inefficient
    system("aws s3 cp --recursive public/assets s3://#{COMPILED_ASSETS_BUCKET}/#{@target_group_name}/#{checksum}")
  end
end
