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
class AwsQuickSight
  attr_reader :aws_acct_id
  attr_reader :ds_group_name

  def initialize(aws_acct_id: ENV.fetch('AWS_QUICKSIGHT_ACCOUNT_ID'))
    @aws_acct_id = ENV.fetch('AWS_QUICKSIGHT_ACCOUNT_ID')
    @ds_group_name = ENV.fetch('AWS_QUICKSIGHT_DS_GROUP_NAME')
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
  def sign_in_url(user:)
    raise 'TODO'
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
