###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module GrdaWarehouse
	module Encryption
		class Secret < GrdaWarehouseBase
      self.table_name = 'encryption_secrets'

			validates :current, inclusion: { in: [true, false] }
			validates :previous, inclusion: { in: [true, false] }
			validates :version_stage, uniqueness: true, presence: true
			validate :sane_rotation
			validate :sane_current
			validate :sane_previous

			scope :sorted, -> { order(created_at: :desc) }

			def self.current
				find_by(current: true)
			end

			def self.previous
				find_by(previous: true)
			end

      def rotate!(&block)
        return if Util.new.encryption_disabled?

        if block_given?
          SecretRotation.new(self).run!(&block)
        else
          SecretRotation.new(self).run!
        end
      end

			def plaintext_key
        Util.new.get_key(version_id)
			end

			private

			def sane_rotation
				return if rotated_at.nil?

				if current?
					errors[:current] << "cannot be true when it's considered rotated"
				end
			end

			def sane_current
				return unless current?

				if persisted?
					if Secret.where(current: true).where.not(id: self.id).any?
						errors[:current] << "cannot be current if another is already"
					end
				else
					if Secret.where(current: true).any?
						errors[:current] << "cannot be current if another is already"
					end
				end
			end

			def sane_previous
				return unless previous?

				if persisted?
					if Secret.where(previous: true).where.not(id: self.id).any?
						errors[:previous] << "cannot be true if another is already"
					end
				else
					if Secret.where(previous: true).any?
						errors[:previous] << "cannot be true if another is already"
					end
				end

				if current?
					errors[:previous] << "cannot be true if also current"
				end
			end
		end
	end
end
