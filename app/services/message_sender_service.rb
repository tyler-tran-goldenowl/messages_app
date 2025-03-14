require 'json'
require 'net/http'

class MessageSenderService
  # Constants
  HOOKBIN_ENDPOINT = ENV.fetch('HOOKBIN_ENDPOINT', 'https://eotx9la2xahfru6.m.pipedream.net')

  attr_reader :message

  def initialize(message)
    @message = message
  end

  def send_message
    return if message.sent_at.present?

    # Dispatch to appropriate sender method based on message type
    case message.message_type.to_sym
    when :birthday
      send_birthday_message
    else
      Rails.logger.error("Unknown message type: #{message.message_type}")
      false
    end
  end

  private

  def send_birthday_message
    uri = URI('https://eotx9la2xahfru6.m.pipedream.net')
    req = Net::HTTP::Post.new(uri, 'Content-Type' => 'application/json')

    req.body = {
      message: I18n.t('messages.birthday', name: message.user.full_name)
    }.to_json

    Net::HTTP.start(uri.hostname, uri.port, :use_ssl => uri.scheme == 'https') do |http|
      http.request(req)
    end
  end
end
