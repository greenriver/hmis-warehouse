###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# View that provides latest custom assessments for destination clients
# This enables easy joining to get CDE values from the most recent assessments per form type
class Hmis::DestinationClientLatestAssessment < GrdaWarehouseBase
  # database view
  self.table_name = 'hmis_destination_client_latest_assessments'
  def readonly? = true

  belongs_to :destination_client, class_name: 'GrdaWarehouse::Hud::Client'
  belongs_to :custom_assessment, class_name: 'Hmis::Hud::CustomAssessment'
  belongs_to :data_source, class_name: 'GrdaWarehouse::DataSource'

  # Narrow to view rows whose latest assessment has a CustomDataElement (for the given definition)
  # with a value in `filter_values`. Values are compared as `column::text IN (...)` so HUD/UI string
  # filter values behave predictably. Mirrors the query in `CdeFieldMap#client_query`.
  #
  # The caller is responsible for any `destination_client_id` bound (e.g. to candidate clients) and
  # for skipping empty `filter_values`. Bounding by `destination_client_id` lets Postgres push the
  # restriction into the view's `DISTINCT ON`, avoiding a correlated subquery against the heavy view.
  #
  # @param cded [Hmis::Hud::CustomDataElementDefinition] the CDE definition to match on
  # @param filter_values [Array<String,#to_s>] values to match (e.g. ['English', 'Spanish'])
  scope :with_cde_value, ->(cded, filter_values) do
    conn = ActiveRecord::Base.connection
    cde_t = Hmis::Hud::CustomDataElement.arel_table
    cde_tbl = Hmis::Hud::CustomDataElement.quoted_table_name
    value_col = conn.quote_column_name(cded.cde_arel_field.name.to_s)

    where(data_source_id: cded.data_source_id).
      where(form_identifier: cded.form_definition_identifier).
      joins(custom_assessment: :custom_data_elements).
      where(cde_t[:data_element_definition_id].eq(cded.id)).
      where(["(#{cde_tbl}.#{value_col})::text IN (?)", filter_values])
  end
end
