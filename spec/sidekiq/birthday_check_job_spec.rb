require 'rails_helper'

RSpec.describe BirthdayCheckJob, type: :job do
  describe '#perform' do
    it 'creates birthday messages for users with birthdays at 9am in their timezone' do
      # Create a user with a birthday today and 9am in their timezone
      user = create(:user)

      # Mock the user's should_send_birthday_message? method to return true
      allow_any_instance_of(User).to receive(:should_send_birthday_message?).and_return(true)

      # Expect the create_birthday_message_if_needed method to be called
      expect_any_instance_of(User).to receive(:create_birthday_message_if_needed)

      # Run the job
      BirthdayCheckJob.new.perform
    end

    it 'does not create birthday messages for users without birthdays today' do
      # Create a user without a birthday today
      user = create(:user)

      # Mock the user's should_send_birthday_message? method to return false
      allow_any_instance_of(User).to receive(:should_send_birthday_message?).and_return(false)

      # Expect the create_birthday_message_if_needed method not to be called
      expect_any_instance_of(User).not_to receive(:create_birthday_message_if_needed)

      # Run the job
      BirthdayCheckJob.new.perform
    end

    it 'logs information about created birthday messages' do
      # Create a user with a birthday today and 9am in their timezone
      user = create(:user)

      # Mock the user's should_send_birthday_message? method to return true
      allow_any_instance_of(User).to receive(:should_send_birthday_message?).and_return(true)

      # Mock the user's create_birthday_message_if_needed method
      allow_any_instance_of(User).to receive(:create_birthday_message_if_needed)

      # Expect logging
      expect(Rails.logger).to receive(:info).with(/Running BirthdayCheckJob/)
      expect(Rails.logger).to receive(:info).with(/Created birthday message for user #{user.id}/)

      # Run the job
      BirthdayCheckJob.new.perform
    end
  end
end
