###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module RuboCop
  module Cop
    module Migrations
      # Flags any use of `disable_ddl_transaction!` in a migration.
      #
      # It drops the migration's wrapping transaction, so if any statement
      # after it fails (most commonly a lock timeout on a concurrent index
      # build), earlier statements in the migration stay committed, but the
      # migration is never recorded as run. A retry then re-runs those
      # earlier statements (e.g. PG::DuplicateColumn on a repeated
      # add_column) and cancels the rest of the deploy.
      #
      class DisableDdlTransaction < RuboCop::Cop::Base
        MSG = '`disable_ddl_transaction!` removes the migration\'s wrapping transaction, so a failure partway ' \
              'through (e.g. a lock timeout on a concurrent index build) leaves earlier statements committed ' \
              'without the migration being recorded, breaking retries on the next deploy. Prefer a plain, ' \
              'transactional add_index when the table is new/small. If concurrent index creation is genuinely ' \
              'transactional add_index when the table is new/small. If concurrent index creation is genuinely ' \
              'needed, isolate it in its own migration and add `rubocop:disable Migrations/DisableDdlTransaction` with a comment explaining why.'

        def on_send(node)
          return unless node.method?(:disable_ddl_transaction!)

          add_offense(node)
        end
      end
    end
  end
end
