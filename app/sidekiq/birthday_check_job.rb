class BirthdayCheckJob
  include Sidekiq::Job

  queue_as :default

  # This job runs every hour and checks if any users have birthdays
  # It creates pending birthday messages for users who have birthdays and
  # where it's 9am in their timezone
  def perform
    Rails.logger.info("Running BirthdayCheckJob at #{Time.current}")

    # Find all users
    User.with_birthday_today.find_each do |user|
      # Check if it's the user's birthday and if it's 9am in their timezone
      user_time = Time.current.in_time_zone(user.timezone)
      if user_time.hour == 9 && user_time.min >= 0
        message = user.create_birthday_message_if_needed

        if message
          Rails.logger.info("Created birthday message for user #{user.id} (#{user.full_name})")
          MessageSenderService.new(message).send_message
        end
      end
    end
  end

  private

  # Create a pending birthday message if it doesn't exist yet
  def create_birthday_message_if_needed(user)
    today = Time.current.in_time_zone(user.timezone).to_date
    # Only create if no birthday message exists for today
    return if user.messages.birthday.where("DATE(created_at) = ?", today).exists?

    # Create a new birthday message
    user.messages.create!(message_type: :birthday)
  end
end
