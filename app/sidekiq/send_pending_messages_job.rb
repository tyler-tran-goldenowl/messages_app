class SendPendingMessagesJob
  include Sidekiq::Job

  def perform
    Rails.logger.info("Running SendPendingMessagesJob at #{Time.current}")

    Message.pending.find_each do |message|
      # Send the message using our service
      service = MessageSenderService.new(message)
      success = service.send_message
      Rails.logger.info("Sent #{message.message_type} message #{message.id} to user #{message.user_id}: #{success ? 'SUCCESS' : 'FAILED'}")
    end
  end
end
