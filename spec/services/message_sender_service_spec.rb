require 'rails_helper'

RSpec.describe MessageSenderService, type: :service do
  describe '#send_message' do
    let!(:user) { create(:user, timezone: 'UTC') }
    let!(:message) { create(:message, user: user, message_type: :birthday) }
    let(:service) { MessageSenderService.new(message) }

    context 'when the message is already sent' do
      it 'returns early without making an HTTP request' do
        message.update!(sent_at: Time.current)

        expect(Net::HTTP).not_to receive(:start)

        result = service.send_message

        expect(result).to be_nil
      end
    end

    context 'when sending a valid message' do
      let(:http_double) { instance_double(Net::HTTP) }
      let(:response_double) { instance_double(Net::HTTPResponse, code: '200') }

      before do
        allow(Net::HTTP).to receive(:start).and_yield(http_double)
        allow(http_double).to receive(:request).and_return(response_double)
      end

      it 'sends the message via HTTP' do
        expect(Net::HTTP::Post).to receive(:new).with(
          URI(ENV['HOOKBIN_ENDPOINT']),
          'Content-Type' => 'application/json'
        ).and_call_original

        service.send_message
      end

      it 'sets the correct request body' do
        expect_any_instance_of(Net::HTTP::Post).to receive(:body=).with(
          { message: I18n.t('messages.birthday', name: user.full_name) }.to_json
        )

        service.send_message
      end
    end

    context 'with unknown message type' do
      before do
        allow(message).to receive(:message_type).and_return('unknown_type')
      end

      it 'logs an error and returns false' do
        expect(Rails.logger).to receive(:error).with(/Unknown message type: unknown_type/)

        result = service.send_message

        expect(result).to eq(false)
      end
    end

    context 'when an exception occurs' do
      before do
        allow(Net::HTTP).to receive(:start).and_raise(StandardError.new('Network error'))
      end

      it 'catches the exception, logs the error and returns false' do
        expect(Rails.logger).to receive(:error).with('Error sending message: Network error')

        result = service.send_message

        expect(result).to eq(false)
      end
    end
  end
end
