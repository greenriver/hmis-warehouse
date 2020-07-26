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
require 'aws-sdk-cognitoidentity'
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
        "Action": "sts:GetFederationToken",
        "Resource": "*"
      },
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
  attr_reader :ds_group_name

  def initialize(aws_acct_id: ENV.fetch('AWS_QUICKSIGHT_ACCOUNT_ID'))
    @aws_acct_id = ENV.fetch('AWS_QUICKSIGHT_ACCOUNT_ID')
    @ds_group_name = ENV.fetch('AWS_QUICKSIGHT_DS_GROUP_NAME')
  end

  # Can the user use or request access to QuickSight?
  def available_to?(user)
    return false unless user
    raise ArgumentError, 'user must be a User' unless user.is_a?(::User)

    cognito_id_token_for_user(user) || aws_credential_for_user(user)
  end

  def cognito_idp_enabled?
    ENV['AWS_COGNITO_APP_ID'].present?
  end

  def cognito_id_token_for_user(user)
    raise ArgumentError, 'user must be a User' unless user.is_a?(::User)

    cognito_idp_enabled? && user.provider == 'cognito' && user.provider_raw_info&.dig('id_token')
  end

  def aws_credential_for_user(user, create_if_missing: false)
    cred = AwsCredential.find_by(user: user, account_id: aws_acct_id)
    return cred unless create_if_missing

    # now confirm with AWS that the saved key still exists
    existing_key = if cred
      begin
        iam_admin.list_access_keys(
          user_name: cred.username,
        ).access_key_metadata.detect{ |k| k.access_key_id == cred.access_key_id}
      rescue Aws::IAM::Errors::NoSuchEntity
        existing_cred.destroy # key disappear
        nil
      end
    end
    cred.destroy if cred && !existing_key # its gone.. remove it so we dont get confused

    unless existing_key
      # Note, This is a create! since a new key is only
      # returned once. Should the database save fail
      # we would need to add logic to remove the orphaned key.
      # Any given IAM account can have at most 2 keys
      cred = AwsCredential.where(user: user, account_id: aws_acct_id).first_or_create! do |new_cred|
        new_cred.default_username!
        iam_user = iam_admin.get_user(user_name: new_cred.username)
        iam_user ||= begin
          new_user = iam_admin.create_user(user_name: cred.username, tags: [{key: 'hmis_warehouse_user_id', value: "#{user.id}"}])
          iam_admin.wait_until(:user_exists, user_name: new_cred.username)
        end
        new_key = iam_admin.create_access_key(user_name: new_cred.username).access_key
        new_cred.access_key_id = new_key.access_key_id
        new_cred.secret_access_key = new_key.secret_access_key
      end
    end
    cred
  end

  DEFAULT_IAM_AUTHOR_POLICY_NAME = -'OpenPath_QuickSight_Author'
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
    # check that we have some sort of ID we can use with AWS services
    qs_user = if cognito_id_token_for_user(user)
      raise 'FIXME'
    else
      # make sure the IAM user exists and has the right policy attached
      cred = aws_credential_for_user(user, create_if_missing: true)
      policy = author_policy(create_if_missing: true)
      iam_admin.attach_user_policy(user_name: cred.username, policy_arn: policy.arn)

      # make sure the quick sight user exists
      author_qs_user(aws_credential: cred, create_if_missing: true)
    end

    # make sure the quick sight group exists
    group!(group_name: ds_group_name)

    # make sure the quick sight group exists
    create_group_membership(user_name: qs_user.user_name,  group_name: ds_group_name)

    qs_user
  end

  # Given a `User` instance revoke their access
  # to Quick Sight.
  def revoke_user_access(user)
    raise 'TODO'
  end

  def qs_users
    qs_admin.list_users(aws_account_id: aws_acct_id, namespace: :default)
  end

  def author_qs_user(aws_credential:, create_if_missing: true)
    existing_user = begin
      qs_admin.describe_user(
        user_name: aws_credential.username,
        aws_account_id: aws_acct_id,
        namespace: QS_NAMESPACE,
      ).user
    rescue Aws::QuickSight::Errors::ResourceNotFoundException
      nil
    end

    return existing_user unless create_if_missing

    # "Currently, you use the ID for the AWS account that contains your Amazon QuickSight account."
    # - https://docs.aws.amazon.com/sdk-for-ruby/v3/api/Aws/QuickSight/Client.html#register_user-instance_method
    # July 25 2020
    existing_user || qs_admin.register_user(
      identity_type: 'IAM',
      email: aws_credential.user.email,
      user_role: "AUTHOR",
      iam_arn: aws_credential.arn,
      namespace: QS_NAMESPACE,
      aws_account_id: aws_acct_id,
      #user_name: aws_credential.username,
    ).user
  end

  DEFAULT_IAM_AUTHOR_ROLE_NAME = 'OpenPath_QuickSight_Login'
  def author_iam_role(create_if_missing: true)
    role_arn = "arn:aws:iam::#{aws_acct_id}:role/#{DEFAULT_IAM_AUTHOR_ROLE_NAME}"
    role = iam_admin.get_role(role_arn: role_arn).role
    role ||= if create_if_missing
      raise 'FIXME'
    end
  end

  def author_iam_role_statement
    {
      "Version": "2012-10-17",
      "Statement": [
        {
          "Effect": "Allow",
          "Principal": {
            "Federated": "cognito-identity.amazonaws.com"
          },
          "Action": "sts:AssumeRoleWithWebIdentity",
          "Condition": {
            "StringEquals": {
              "cognito-identity.amazonaws.com:aud": identity_pool.identity_pool_id
            }
          }
        }
      ]
    }
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
      'Session': federation_session(user, session_duration: session_duration).to_json,
    }.to_param

    json = JSON.parse(RestClient.get(sign_in_token_url))

    login_url = AWS_FEDERATION_ENDPOINT+{
      'Action': 'login',
      'Issuer': return_to_url,
      'Destination': START_URL,
      'SigninToken': json['SigninToken']
    }.to_param
  end

  def federation_session(user, session_duration: session_duration)
    # full IAM users are fastest to login
    if (aws_credential = aws_credential_for_user(user))
      aws_credential_based_session(aws_credential, user: user, session_duration: session_duration)
    elsif (id_token = cognito_id_token_for_user(user))
      cognito_id_token_based_session(user.provider_raw_info['id_token'])
    else
      raise ArgumentError, 'User does not support AWS federated login.'
    end
  end

  private def aws_credential_based_session(aws_credential, user: aws_credential.user, session_duration: )
    user_sts = Aws::STS::Client.new(
      access_key_id: aws_credential.access_key_id,
      secret_access_key: aws_credential.secret_access_key,
    )
    resp = user_sts.get_federation_token(
      name: aws_credential.username[0..32], # docs say this can be up to 32 chars while an AWS IAM is up to 64... odd
      policy_arns: [{arn: author_policy.arn}],
      duration_seconds: session_duration,
    )
    creds = resp.credentials
    {
      'sessionId': creds.access_key_id,
      'sessionKey': creds.secret_access_key,
      'sessionToken': creds.session_token
    }
  end

  private def identity_pool(create_if_missing: true)
    pool_name = ENV.fetch('HOSTNAME').split('.').first[0..128]

    # find the existing pool by name
    existing_pool_id =  nil
    cognito_admin.list_identity_pools(max_results: 50).each do |batch|
      batch.identity_pools.each do |pool|
        existing_pool_id = pool.identity_pool_id if pool.identity_pool_name == pool_name
        break if existing_pool_id
      end
      break if existing_pool_id
    end

    pool = cognito_admin.describe_identity_pool(identity_pool_id: existing_pool_id) if existing_pool_id
    pool ||= if create_if_missing
      cognito_admin.create_identity_pool(
        identity_pool_name: pool_name, # required
        developer_provider_name: host_name,
        allow_unauthenticated_identities: false,
        cognito_identity_providers: [
          {
            provider_name: cognito_idp,
            client_id: ENV.fetch('AWS_COGNITO_APP_ID'),
            server_side_token_check: false,
          }
        ],
        identity_pool_tags: {
          'env' => Rails.env.to_s,
        },
      )
    end

    authenticated_role_arn = cognito_admin.get_identity_pool_roles(
      identity_pool_id: pool.identity_pool_id,
    ).roles&.dig('authenticated')

    unless authenticated_role_arn
      cognito_admin.set_identity_pool_roles(
        identity_pool_id: pool.identity_pool_id,
        roles: {
          'authenticated' => author_iam_role.arn
        }
      )
    end

    pool
  end

  private def cognito_idp
    cognito_region = ENV.fetch('AWS_COGNITO_REGION')
    user_pool_id = ENV.fetch('AWS_COGNITO_POOL_ID')
    "cognito-idp.#{cognito_region}.amazonaws.com/#{user_pool_id}"
  end

  private def cognito_id_token_based_session(id_token)
    identity_pool_id = identity_pool(create_if_missing: true).identity_pool_id
    identity_id = Aws::CognitoIdentity::Client.new.get_id(
      identity_pool_id: identity_pool_id,
      logins: {
        cognito_idp => id_token
      },
    ).identity_id

    # resp = client.get_open_id_token_for_developer_identity({
    #   identity_pool_id: "IdentityPoolId", # required
    #   identity_id: "IdentityId",
    #   logins: { # required
    #     "IdentityProviderName" => "IdentityProviderToken",
    #   },
    # })

    session = Aws::CognitoIdentity::Client.new.get_credentials_for_identity(
      identity_id: identity_id,
      logins: {
        cognito_idp => id_token
      },
    ).credentials

    {
      'sessionId': session.access_key_id,
      'sessionKey': session.secret_key,
      'sessionToken': session.session_token
    }
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
  def iam_admin
    Aws::IAM::Client.new(credentials: admin_credentials)
  end

  def cognito_admin
    Aws::CognitoIdentity::Client.new(credentials: admin_credentials)
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
    # there appears to be some race on the Quick Sight side
    # if we call add to quickly after delete
    #
    # the API doesn't have a waiter for this currently
    # doing this lame thing for now
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

    # TODO: remove this... the race condition her
    # appears to have been calling create_group too soon after delete_group
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
  def create_group_membership(user_name:, group_name: ds_group_name)
    qs_admin.create_group_membership(
      member_name: user_name,
      group_name: ds_group_name,
      aws_account_id: aws_acct_id,
      namespace: QS_NAMESPACE,
    )
  end

  # Removes a QS user (by their QuickSight username) to a group.
  # Ignores if the user is already in the group
  def delete_group_membership(user_name:, group_name: ds_group_name)
    qs_admin.delete_group_membership(
      member_name: user_name,
      group_name: ds_group_name,
      aws_account_id: aws_acct_id,
      namespace: QS_NAMESPACE,
    )
  end
end
