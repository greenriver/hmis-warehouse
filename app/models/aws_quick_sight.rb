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

  # A namespace allows you to isolate the QuickSight users and groups
  # that are registered for that namespace. Users that access the
  # namespace can share assets only with other users or groups in the
  # same namespace. They can't see users and groups in other namespaces.
  # You can create a namespace after your AWS account is subscribed to
  # QuickSight. The namespace must be unique within the AWS account. By
  # default, there is a limit of 100 namespaces per AWS account. To
  # increase your limit, create a ticket with AWS Support.
  # - https://docs.aws.amazon.com/quicksight/latest/APIReference/API_CreateNamespace.html
  QS_NAMESPACE = :default


  # the aws_account_id that contains the quicksight ins
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

  def qs_users
    qs_admin.list_users(aws_account_id: aws_acct_id, namespace: :default)
  end

  def qs_user(user_name)
    qs_admin.describe_user({
      user_name: user_name, # required
      aws_account_id: aws_acct_id, # required
      namespace: QS_NAMESPACE, # required
    }).user
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

  private def federation_credentials(user)
    credentials = if self.class.available_to?(user)
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
      'sessionId': credentials.credentials.access_key_id,
      'sessionKey': credentials.credentials.secret_key,
      'sessionToken': credentials.credentials.session_token
    }
  end

  # Given a valid email addresses them up with access
  # to QuickSight as (TODO).
  #
  # returns true of the user was removed, false if they
  # already existed and raises if provisioning is not possible
  # at this time
  def provision_external_user_access(email: )
    raise 'TODO'
  end

  # Given a valid email addresses them up with access
  # to QuickSight as (TODO).
  #
  # returns true of the user was removed, false if they
  # already existed and raises if provisioning is not possible
  # at this time
  def revoke_external_user_access(email: )
    raise 'TODO'
  end

  # :nodoc:
  private def admin_credentials
    Aws::SharedCredentials.new.credentials
  end

  # :nodoc:
  def qs_admin
    Aws::QuickSight::Client.new(credentials: admin_credentials)
  end

  # :nodoc:
  private def warehouse_db_data_source_id
    ENV.fetch('AWS_QUICKSIGHT_DATA_SOURCE_ID')
  end

  # :nodoc:
  #
  # DANGER: This will remove all users from the group
  # you will have to delete_group_membership
  # and create_group_membership with
  # some unknown delay between them
  def recreate_group!(group_name: ds_group_name)
    delete_group(group_name: group_name)
    # there appears to be some race on the quicksight side
    # if we call add to quickly after delete
    wait_time = 20
    Rails.logger.info("waiting #{wait_time}s for delete to complete")
    sleep wait_time
    add_group(group_name: group_name)
  end

  # :nodoc:
  def group!(group_name: ds_group_name)
    group(group_name: group_name) || add_group(group_name: group_name)
  end

  # :nodoc:
  def group(group_name: ds_group_name)
    qs_admin.describe_group(
      namespace: QS_NAMESPACE,
      aws_account_id: aws_acct_id,
      group_name: group_name
    ).group
  rescue Aws::QuickSight::Errors::ResourceNotFoundException
    nil
  end

  # :nodoc:
  def add_group(group_name: ds_group_name)
    qs_admin.create_group(
      namespace: QS_NAMESPACE,
      aws_account_id: aws_acct_id,
      group_name: group_name,
    ) rescue Aws::QuickSight::Errors::ResourceExistsException

    the_group = nil
    retries = [1,2,4,8,16]
    retries.each do |back_off|
      the_group = group(group_name: group_name)
      puts the_group
      break if the_group
      sleep back_off
    end
    raise "After `create_group` succeeded, `describe_group` returned ResourceNotFoundException after #{retries.sum} seconds of retries." unless the_group

    group_arn = the_group.arn

    use_data_source = [
      'quicksight:DescribeDataSource',
      'quicksight:DescribeDataSourcePermissions',
      'quicksight:PassDataSource',
    ]

    qs_admin.update_data_source_permissions(
      aws_account_id: aws_acct_id,
      data_source_id: warehouse_db_data_source_id,
      grant_permissions: [
        { principal: group_arn, actions: use_data_source},
      ],
    )

    the_group
  end

  # :nodoc:
  def delete_group(group_name: ds_group_name)
    qs_admin.delete_group(
      namespace: QS_NAMESPACE,
      aws_account_id: aws_acct_id,
      group_name: group_name
    )
  end

  # Add a QS user (by their QuickSight username) to a group.
  # Does nothing
  def create_group_membership(username:, group_name: ds_group_name)
    qs_admin.create_group_membership(
      member_name: username,
      group_name: ds_group_name,
      aws_account_id: aws_acct_id,
      namespace: QS_NAMESPACE,
    )
  end

  # Removes a QS user (by their QuickSight username) to a group.
  # Ignores if the user is already in the group
  def delete_group_membership(username:, group_name: ds_group_name)
    qs_admin.delete_group_membership(
      member_name: username,
      group_name: ds_group_name,
      aws_account_id: aws_acct_id,
      namespace: QS_NAMESPACE,
    )
  end
end
