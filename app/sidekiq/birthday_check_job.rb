class BirthdayCheckJob
  include Sidekiq::Job

  queue_as :default

  def perform
    Rails.logger.info("Running BirthdayCheckJob at #{Time.current}")

    User.with_birthday_today.find_each do |user|
      user_time = Time.current.in_time_zone(user.timezone)
      if user_time.hour == 9 && user_time.min >= 0
        message = create_birthday_message_if_needed(user)

        if message
          Rails.logger.info("Created birthday message for user #{user.id} (#{user.full_name})")
          MessageSenderService.new(message).send_message
        end
      end
    end
  end

  private

  def create_birthday_message_if_needed(user)
    today = Time.current.in_time_zone(user.timezone).to_date
    return if user.messages.birthday.where("DATE(created_at) = ?", today).exists?

    user.messages.create!(message_type: :birthday)
  end
end
