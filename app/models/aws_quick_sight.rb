###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# As of July 2020 a Enterprise level QuickSight account is required.
# See https://docs.aws.amazon.com/quicksight/latest/user/managing-users-enterprise.html
# for background.
#
# It may be possible to adapt to use Standard Edition features but would
# require separate accounts for different user groups since at the time of this
# writing standard edition does not support groups or access to AWS
# resources over a VPC

require 'aws-sdk-quicksight'
require 'aws-sdk-cognitoidentity'
require 'restclient' #FIXME we use this in only one place HTTP::get would be fine

class AwsQuickSight
  START_URL = 'https://quicksight.aws.amazon.com/'
  AWS_FEDERATION_ENDPOINT = 'https://signin.aws.amazon.com/federation?'
  VALID_SESSION_DURATIONS = (1.hours..12.hours)


  attr_reader :aws_acct_id

  # this needs to be unique for each user group
  attr_reader :ds_group_name

  def initialize(aws_acct_id: ENV.fetch('AWS_QUICKSIGHT_ACCOUNT_ID'))
    @aws_acct_id = ENV.fetch('AWS_QUICKSIGHT_ACCOUNT_ID')
    @ds_group_name = ENV.fetch('AWS_QUICKSIGHT_DS_GROUP_NAME')
  end


  # Can the user use or request access to QuickSight?
  def self.available_to?(user)
    cognito_idp_enabled? && user.provider_raw_info.present?
  end

  def self.cognito_idp_enabled?
    ENV['AWS_COGNITO_APP_ID'].present?
  end

  # Given a `User` instance set them up with access
  # to QuickSight as an author with the warehouse database
  # as a pre-approved data source.
  #
  # returns true of the user was removed, false if they
  # already existed and raises if provisioning is not possible
  # at this time
  def provision_user_access(user: , initial_group: nil)
    raise 'TODO'
  end

  # Given a `User` instance revoke their access
  # to Quick Sight.
  def revoke_user_access(user: )
    raise 'TODO'
  end

  # given a `User` return a time-expiring URL
  # for them to login to QuickSight
  #
  # this makes and waits on a HTTP get to AWS_FEDERATION_ENDPOINT
  def sign_in_url(user:, return_to_url:, session_duration: 8.hours)
    raise ArgumentError, "session duration needs be in the range #{VALID_SESSION_DURATIONS}" unless VALID_SESSION_DURATIONS === session_duration

    sign_in_token_url = AWS_FEDERATION_ENDPOINT+{
      'Action': 'getSigninToken',
      'SessionDuration': session_duration,
      'Session': federation_credentials(user).to_json,
    }.to_param

    json = JSON.parse(RestClient.get(sign_in_token_url))

    login_url = AWS_FEDERATION_ENDPOINT+{
      'Action': 'login',
      'Issuer': return_to_url,
      'Destination': START_URL,
      'SigninToken': json['SigninToken']
    }.to_param
  end

  def federation_credentials(user)
    credentials = if self.available_to?(user)
      cognito_region = ENV.fetch('AWS_COGNITO_REGION')
      user_pool_id = ENV.fetch('AWS_COGNITO_POOL_ID')
      identity_pool_id = ENV.fetch('AWS_COGNITO_IDENTITY_POOL_ID')

      login_key = "cognito-idp.#{cognito_region}.amazonaws.com/#{user_pool_id}"
      identity_id = Aws::CognitoIdentity::Client.new.get_id(
        identity_pool_id: identity_pool_id,
        logins: {
          login_key => user.provider_raw_info['id_token']
        },
      ).identity_id

      Aws::CognitoIdentity::Client.new.get_credentials_for_identity(
        identity_id: identity_id,
        logins: {
          login_key => user.provider_raw_info['id_token']
        },
      )
    else
      raise ArgumentError, 'Only supported for users logging in via AWS Cognito'
    end

    {
      "sessionId": credentials.credentials.access_key_id,
      "sessionKey": credentials.credentials.secret_key,
      "sessionToken": credentials.credentials.session_token
    }
  end

  # Given a valid email addresses them up with access
  # to QuickSight as (TODO).
  #
  # returns true of the user was removed, false if they
  # already existed and raises if provisioning is not possible
  # at this time
  def provision_external_user_access(email: )
  end

  # Given a valid email addresses them up with access
  # to QuickSight as (TODO).
  #
  # returns true of the user was removed, false if they
  # already existed and raises if provisioning is not possible
  # at this time
  def revoke_external_user_access(email: )
  end

  # :nodoc:
  def admin_credentials
    Aws::SharedCredentials.new.credentials
  end

  # :nodoc:
  def qs_admin
    Aws::QuickSight::Client.new(credentials: admin_credentials)
  end

  # :nodoc:
  def warehouse_db_data_source_id
    ENV.fetch('AWS_QUICKSIGHT_DATA_SOURCE_ID')
  end

  # :nodoc:
  def ds_group!
    ds_group || add_ds_group
  end

  # :nodoc:
  def ds_group
    qs_admin.describe_group(
      namespace: :default,
      aws_account_id: aws_acct_id,
      group_name: ds_group_name
    ).group
  rescue Aws::QuickSight::Errors::ResourceNotFoundException
    nil
  end

  # :nodoc:
  def add_ds_group
    qs_admin.create_group(
      namespace: :default,
      aws_account_id: aws_acct_id,
      group_name: ds_group_name
    ) rescue Aws::QuickSight::Errors::ResourceExistsException

    ds_group_arn = ds_group.arn

    use_data_source = ["quicksight:DescribeDataSource",
          "quicksight:DescribeDataSourcePermissions",
          "quicksight:PassDataSource"]

    qs_admin.update_data_source_permissions(
      aws_account_id: aws_acct_id,
      data_source_id: warehouse_db_data_source_id,
      grant_permissions: [
        { principal: ds_group_arn, actions: use_data_source},
      ],
    )

    ds_group
  end

  # :nodoc:
  def delete_ds_group
    qs_admin.delete_group(
      namespace: :default,
      aws_account_id: aws_acct_id,
      group_name: ds_group_name
    )
  end

  def add_user_to_group(user_arn:, group_arn:)
  end

  # :nodoc:
  def remove_user_from_group(user_arn:, group_arn:)
  end
end
