require 'rails_helper'

RSpec.describe Message, type: :model do
  describe 'associations' do
    it { should belong_to(:user) }
  end

  describe 'enumerized attributes' do
    it 'has message_type enumerized' do
      expect(Message.message_type.values).to contain_exactly('birthday')
    end
  end

  describe '#mark_sent!' do
    it 'marks the message as sent and sets the sent_at timestamp' do
      message = create(:message)

      expect {
        message.mark_sent!
      }.to change { message.sent_at }.from(nil)

      expect(message.sent_at).not_to be_nil
    end
  end
end
