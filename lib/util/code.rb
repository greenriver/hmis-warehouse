###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class Code
  def self.copyright_header
    <<~COPYRIGHT
      ###
      # Copyright Green River Data Group, Inc.
      #
      # License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
      ###

    COPYRIGHT
  end

  def self.strip_old_copyright(content)
    old_copyright_pattern = /###\n# Copyright \d{4} - \d{4} Green River Data Analysis, LLC\n#\n# License detail: https:\/\/github\.com\/greenriver\/hmis-warehouse\/blob\/(?:production|stable)\/LICENSE\.md\n###\n*/
    content.sub(old_copyright_pattern, '')
  end
end
