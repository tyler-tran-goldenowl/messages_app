require 'rails_helper'

RSpec.describe MessageSenderService, type: :service do
  describe '#send_message' do
    let(:user) { create(:user, first_name: 'John', last_name: 'Doe') }
    let(:message) { create(:message, user: user, message_type: :birthday) }
    let(:service) { MessageSenderService.new(message) }

    context 'when the message is already sent' do
      it 'returns early without making an HTTP request' do
        message.update(status: :sent, sent_at: Time.current)

        expect(HTTParty).not_to receive(:post)

        result = service.send_message
        expect(result).to be_nil
      end
    end

    context 'when the retry count exceeds the maximum' do
      it 'marks the message as failed without making an HTTP request' do
        message.update(retry_count: Message::MAX_RETRIES)

        expect(HTTParty).not_to receive(:post)

        expect {
          service.send_message
        }.to change { message.status.to_s }.from('pending').to('failed')
      end
    end

    context 'when sending a birthday message' do
      context 'when the HTTP request is successful' do
        it 'marks the message as sent' do
          # Mock the HTTP response
          response = instance_double(HTTParty::Response, success?: true)
          allow(HTTParty).to receive(:post).and_return(response)

          expect {
            result = service.send_message
            expect(result).to be true
          }.to change { message.status.to_s }.from('pending').to('sent')
            .and change { message.sent_at }.from(nil)

          # Verify the HTTP request was made with the correct parameters
          expect(HTTParty).to have_received(:post).with(
            MessageSenderService::HOOKBIN_ENDPOINT,
            body: { message: "Hey, John Doe it's your birthday" }.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )
        end
      end

      context 'when the HTTP request fails' do
        it 'increments the retry count' do
          # Mock the HTTP response
          response = instance_double(HTTParty::Response, success?: false)
          allow(HTTParty).to receive(:post).and_return(response)

          expect {
            result = service.send_message
            expect(result).to be false
          }.to change { message.retry_count }.from(0).to(1)

          expect(message.status.to_s).to eq('pending')
          expect(message.sent_at).to be_nil
        end
      end

      context 'when an exception occurs' do
        it 'logs the error and increments the retry count' do
          # Mock an exception
          allow(HTTParty).to receive(:post).and_raise(StandardError.new('Network error'))

          # Expect logging
          expect(Rails.logger).to receive(:error).with(/Failed to send birthday message/)

          expect {
            result = service.send_message
            expect(result).to be false
          }.to change { message.retry_count }.from(0).to(1)

          expect(message.status.to_s).to eq('pending')
          expect(message.sent_at).to be_nil
        end
      end
    end
  end
end
