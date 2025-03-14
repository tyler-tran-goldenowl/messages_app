class Message < ApplicationRecord
  extend Enumerize

  belongs_to :user

  MESSAGE_TYPES = %i[birthday].freeze

  # Define enumerated values for status and message_type
  enumerize :message_type, in: MESSAGE_TYPES, default: :birthday, predicates: true, scope: :shallow

  scope :pending, -> { where(sent_at: nil) }

  # Mark as sent
  def mark_sent!
    update!(sent_at: Time.current)
  end
end
