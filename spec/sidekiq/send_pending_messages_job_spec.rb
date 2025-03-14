require 'rails_helper'

RSpec.describe SendPendingMessagesJob, type: :job do
  describe '#perform' do
    it 'correctly identifies pending messages and sends them' do
      user = create(:user)
      message = create(:message, user: user)

      expect(Message.pending).to include(message)
      expect(Rails.logger).to receive(:info).with("Running SendPendingMessagesJob at #{Time.current}")
      expect(Rails.logger).to receive(:info).with("Sent #{message.message_type} message #{message.id} to user #{message.user_id}: SUCCESS")

      allow_any_instance_of(MessageSenderService).to receive(:send_message).and_return(true)

      SendPendingMessagesJob.new.perform
    end
  end
end
