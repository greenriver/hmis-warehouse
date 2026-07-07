###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# NOTE: Sometimes we need to fetch data to import from odd FTP servers that
# Ruby can't deal with directly, this will fetch and push to S3 for normal processing
module GrdaWarehouse
  class LsaRdsStateLog < GrdaWarehouseBase

  end
end
