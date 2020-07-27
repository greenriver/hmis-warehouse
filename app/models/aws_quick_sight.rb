###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# Wrapper around various AWS APIs to handle our Quick Sight integrations.

# As of July 2020 a Enterprise level QuickSight account is required.
# See https://docs.aws.amazon.com/quicksight/latest/user/managing-users-enterprise.html
# for background.
#
# It may be possible to adapt to use Standard Edition features but would
# require separate accounts for different user groups since at the time of this
# writing standard edition does not support groups or access to AWS
# resources over a VPC

require 'aws-sdk-quicksight'
require 'aws-sdk-iam'
require 'aws-sdk-sts'
require 'restclient' #FIXME we use this in only one place HTTP::get would be fine

class AwsQuickSight
  START_URL = 'https://quicksight.aws.amazon.com/'
  AWS_FEDERATION_ENDPOINT = 'https://signin.aws.amazon.com/federation?'
  VALID_SESSION_DURATIONS = (1.hours..12.hours)


  # IAM Policy needed for Quick Sight Authors
  AUTHOR_IAM_POLICY = IceNine.deep_freeze(
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Action": [
            "quicksight:CreateUser",
        ],
        "Resource": [
            "arn:aws:quicksight:*:*:user/*"
        ]
      }
    ]
  )

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
  attr_reader :author_role_name

  def initialize(aws_acct_id: ENV.fetch('AWS_QUICKSIGHT_ACCOUNT_ID'))
    @aws_acct_id = ENV.fetch('AWS_QUICKSIGHT_ACCOUNT_ID')
    @author_role_name = ENV.fetch('AWS_QUICKSIGHT_AUTHOR_ROLE_NAME')
    @ds_group_name = @author_role_name
  end

  # Can the user use or request access to QuickSight?
  def available_to?(user)
    return false unless user
    raise ArgumentError, 'user must be a User' unless user.is_a?(::User)
    true
  end

  DEFAULT_IAM_AUTHOR_POLICY_NAME = -'QuickSightAuthor'
  def author_policy_name
    DEFAULT_IAM_AUTHOR_POLICY_NAME
  end

  def author_policy(create_if_missing: false)
    existing_policy = begin
      iam_admin.get_policy(
        policy_arn: "arn:aws:iam::#{aws_acct_id}:policy/#{author_policy_name}"
      ).policy
    rescue Aws::IAM::Errors::NoSuchEntity
      nil
    end
    return existing_policy unless create_if_missing

    existing_policy || iam_admin.create_policy(
      policy_name: author_policy_name,
      policy_document: AUTHOR_IAM_POLICY.to_json,
      description: 'Allow policy holders to become Authors in Quick Sight.'
    ).policy
  end


  # Given a `User` instance ensures that they have access
  # to QuickSight as an author with the warehouse database
  # as a pre-approved data source.
  #
  # raise if the user cannot be setup
  def provision_user_access(user)
    iam_role = author_iam_role(create_if_missing: true)
    session_name = user_session_name(user)
    role_name = iam_role.role_name
    user_name = "#{role_name}/#{session_name}"

    qs_user = begin
      qs_admin.describe_user(
        user_name: user_name,
        namespace: :default,
        aws_account_id: aws_acct_id
      ).user
    rescue Aws::QuickSight::Errors::ResourceNotFoundException
      nil
    end

    qs_user ||= begin
      qs_admin.register_user(
        identity_type: 'IAM',
        user_role: "AUTHOR",
        iam_arn: author_iam_role(create_if_missing: true).arn,
        session_name: session_name,
        email: user.email,
        namespace: :default,
        aws_account_id: aws_acct_id
      ).user
    end

    assign_warehouse_db(qs_user.arn)

    qs_user
  end

  # Given a `User` instance revoke their access
  # to Quick Sight.
  def revoke_user_access(user)
    raise 'TODO'
  end

  def author_iam_role(create_if_missing: true)
    role = begin
      iam_admin.get_role(role_name: author_role_name).role
    rescue Aws::IAM::Errors::NoSuchEntity
      nil
    end

    role ||= if create_if_missing
      iam_admin.create_role(
        role_name: author_role_name,
        max_session_duration: AwsQuickSight::VALID_SESSION_DURATIONS.max,
        assume_role_policy_document: {
          "Version": "2012-10-17",
          "Statement": [
            {
              "Effect": "Allow",
              "Principal": {
                "AWS": sts_admin.get_caller_identity.arn
              },
              "Action": "sts:AssumeRole"
            }
          ]
        }.to_json
      ).role
    end

    iam_admin.attach_role_policy(
      role_name: role.role_name,
      policy_arn: author_policy(create_if_missing: true).arn,
    )
    role
  end

  def valid_return_to?(str)
     uri = URI.parse(str.to_s)
     uri.is_a?(URI::HTTP) && uri.host.present?
  rescue URI::InvalidURIError
    false
  end

  # given a `User` return a time-expiring URL
  # for them to login to QuickSight
  #
  # this makes and waits on a HTTP get to AWS_FEDERATION_ENDPOINT
  def sign_in_url(user:, return_to_url:, session_duration: 8.hours)
    raise ArgumentError, 'user must be a User' unless user.is_a?(::User)
    raise ArgumentError, 'invalid return_to_url' unless valid_return_to?(return_to_url)
    raise ArgumentError, "session duration needs be in the range #{VALID_SESSION_DURATIONS}" unless VALID_SESSION_DURATIONS === session_duration

    sign_in_token_url = AWS_FEDERATION_ENDPOINT+{
      'Action': 'getSigninToken',
      'SessionDuration': session_duration,
      'Session': qs_session(user, session_duration: session_duration).to_json,
    }.to_param

    json = JSON.parse(RestClient.get(sign_in_token_url))

    login_url = AWS_FEDERATION_ENDPOINT+{
      'Action': 'login',
      'Issuer': return_to_url,
      'Destination': START_URL,
      'SigninToken': json['SigninToken']
    }.to_param
  end

  def qs_session(user, session_duration: )
    provision_user_access(user)

    resp = sts_admin.assume_role(
      role_arn: author_iam_role.arn,
      role_session_name: user_session_name(user),
      duration_seconds: session_duration,
    )
    creds = resp.credentials
    {
      'sessionId': creds.access_key_id,
      'sessionKey': creds.secret_access_key,
      'sessionToken': creds.session_token
    }
  end

  def user_session_name(user)
    unless user.uuid.present?
      user.update_columns(uuid: SecureRandom.uuid)
    end

    user.uuid
  end

  def qs_users
    qs_admin.list_users(aws_account_id: aws_acct_id, namespace: :default)
  end

  # :nodoc:
  # private def admin_credentials
  #   Aws::SharedCredentials.new.credentials
  # end

  # :nodoc:
  def iam_admin
    Aws::IAM::Client.new
  end

  # :nodoc:
  def qs_admin
    Aws::QuickSight::Client.new
  end

  # :nodoc:
  def sts_admin
    Aws::STS::Client.new
  end

  # :nodoc:
  private def warehouse_db_data_source_id
    ENV.fetch('AWS_QUICKSIGHT_DATA_SOURCE_ID')
  end

  def warehouse_db_permissons
    qs_admin.describe_data_source_permissions(
      aws_account_id: aws_acct_id,
      data_source_id: warehouse_db_data_source_id,
    )
  end

  def assign_warehouse_db(principal)
    actions = [
      'quicksight:DescribeDataSource',
      'quicksight:DescribeDataSourcePermissions',
      'quicksight:PassDataSource',
    ]
    qs_admin.update_data_source_permissions(
      aws_account_id: aws_acct_id,
      data_source_id: warehouse_db_data_source_id,
      grant_permissions: [
        { principal: principal, actions: actions},
      ],
    )
  end

  def data_source_permissons(data_source_id: )
    qs_admin.describe_data_source_permissions(
      aws_account_id: aws_acct_id,
      data_source_id: data_source_id,
    )
  end

  def assign_data_source(principal, data_source_id: )
    actions = ["quicksight:DescribeDataSource", "quicksight:DescribeDataSourcePermissions", "quicksight:PassDataSource"]
    qs_admin.update_data_source_permissions(
      aws_account_id: aws_acct_id,
      data_source_id: data_source_id,
      grant_permissions: [
        { principal: principal, actions: actions},
      ],
    )
  end

  def assign_data_set(principal, data_set_id: )
    actions = [
      "quicksight:DescribeDataSet",
      "quicksight:DescribeDataSetPermissions",
      "quicksight:PassDataSet",
      "quicksight:DescribeIngestion",
      "quicksight:ListIngestions"
    ]
    qs_admin.update_data_set_permissions(
      aws_account_id: aws_acct_id,
      data_set_id: data_set_id,
      grant_permissions: [
        { principal: principal, actions: actions},
      ],
    )
  end
end
