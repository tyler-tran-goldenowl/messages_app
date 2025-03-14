require 'json'
require 'net/http'

class MessageSenderService
  attr_reader :message

  def initialize(message)
    @message = message
  end

  def send_message
    return if message.sent_at.present?

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
    uri = URI(ENV['HOOKBIN_ENDPOINT'])
    req = Net::HTTP::Post.new(uri, 'Content-Type' => 'application/json')

    req.body = {
      message: I18n.t('messages.birthday', name: message.user.full_name)
    }.to_json

    Net::HTTP.start(uri.hostname, uri.port, :use_ssl => uri.scheme == 'https') do |http|
      http.request(req)
    end

    message.mark_sent!
  rescue => e
    Rails.logger.error("Error sending message: #{e.message}")
    false
  end
end
