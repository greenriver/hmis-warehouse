###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudApr::CellDetailsConcern
  extend ActiveSupport::Concern

  included do
    private def common_fields
      [
        :client_id,
        :first_name,
        :last_name,
        :first_date_in_program,
        :last_date_in_program,
        :head_of_household,
      ].freeze
    end

    private def age_fields
      [
        :age,
        :dob,
      ].freeze
    end

    private def parenting_fields
      [
        :parenting_youth,
        :parenting_juvenile,
      ].freeze
    end

    private def veteran_fields
      [
        :veteran_status,
      ].freeze
    end

    private def homeless_fields
      [
        :chronically_homeless,
        :date_homeless,
        :times_homeless,
        :months_homeless,
      ].freeze
    end

    private def pii_fields
      [
        :ssn,
        :race,
        :ethnicity,
        :gender,
        :gender_multi,
      ].freeze
    end

    private def question_fields(question)
      common_fields +
        {
          'Question 5' => age_fields + parenting_fields + veteran_fields + homeless_fields,
          'Question 6' => pii_fields + veteran_fields,
        }.fetch(question, []).uniq
    end
  end
end
