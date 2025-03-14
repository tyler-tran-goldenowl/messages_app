require 'rails_helper'

RSpec.describe SendPendingMessagesJob, type: :job do
  describe '#perform' do
    let(:redis) { instance_double(Redis) }

    before do
      allow(Redis).to receive(:new).and_return(redis)
      allow(redis).to receive(:set).and_return(true)
      allow(redis).to receive(:del)
    end

    it 'sends all pending messages' do
      # Create some pending messages
      user1 = create(:user, first_name: 'John', last_name: 'Doe')
      user2 = create(:user, first_name: 'Jane', last_name: 'Smith')

      message1 = create(:message, user: user1)
      message2 = create(:message, user: user2)

      # Mock the service
      service1 = instance_double(MessageSenderService)
      service2 = instance_double(MessageSenderService)

      allow(MessageSenderService).to receive(:new).with(message1).and_return(service1)
      allow(MessageSenderService).to receive(:new).with(message2).and_return(service2)

      # Mock the send_message method
      expect(service1).to receive(:send_message).and_return(true)
      expect(service2).to receive(:send_message).and_return(true)

      # Allow finding the messages
      allow(Message).to receive(:with_status).with(:pending).and_return([message1, message2])

      # Run the job
      SendPendingMessagesJob.new.perform
    end

    it 'logs information about sent messages' do
      # Create a pending message
      user = create(:user)
      message = create(:message, user: user, message_type: :birthday)

      # Mock the service
      service = instance_double(MessageSenderService)
      allow(MessageSenderService).to receive(:new).with(message).and_return(service)
      allow(service).to receive(:send_message).and_return(true)

      # Allow finding the message
      allow(Message).to receive(:with_status).with(:pending).and_return([message])

      # Expect logging
      expect(Rails.logger).to receive(:info).with(/Running SendPendingMessagesJob/)
      expect(Rails.logger).to receive(:info).with(/Sent birthday message #{message.id} to user #{user.id}: SUCCESS/)

      # Run the job
      SendPendingMessagesJob.new.perform
    end

    it 'uses a distributed lock to prevent race conditions' do
      # Expect Redis to be used for locking
      expect(redis).to receive(:set).with(
        "send_pending_messages_lock", 1, nx: true, ex: 5.minutes.to_i
      ).and_return(true)

      # Mock empty message list
      allow(Message).to receive(:with_status).with(:pending).and_return([])

      # Run the job
      SendPendingMessagesJob.new.perform

      # Expect the lock to be released
      expect(redis).to have_received(:del).with("send_pending_messages_lock")
    end

    it 'does not process messages if another instance is running' do
      # Mock Redis to indicate another instance is running
      allow(redis).to receive(:set).and_return(false)

      # Expect no messages to be processed
      expect(Message).not_to receive(:with_status)

      # Expect logging
      expect(Rails.logger).to receive(:info).with(/Running SendPendingMessagesJob/)
      expect(Rails.logger).to receive(:info).with(/Another instance is already running/)

      # Run the job
      SendPendingMessagesJob.new.perform
    end
  end
end
