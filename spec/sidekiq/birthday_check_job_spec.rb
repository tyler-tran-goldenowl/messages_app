require 'rails_helper'

RSpec.describe BirthdayCheckJob, type: :job do
  describe '#perform' do
    it 'finds users with birthdays and creates birthday messages' do
      user = create(:user, :birthday_today, timezone: 'UTC')

      travel_to Time.parse('9:00:00 UTC')

      expect(Rails.logger).to receive(:info).with(/Running BirthdayCheckJob/)
      expect(Rails.logger).to receive(:info).with("Created birthday message for user #{user.id} (#{user.full_name})")

      BirthdayCheckJob.new.perform
      travel_back
    end

    it 'skips users when it is not 9am in their timezone' do
      create(:user)
      expect_any_instance_of(BirthdayCheckJob).not_to receive(:create_birthday_message_if_needed)
      BirthdayCheckJob.new.perform
    end

    it 'skips creating duplicate messages' do
      user = create(:user, :birthday_today, timezone: 'UTC')
      create(:message, user: user, message_type: :birthday)

      travel_to Time.parse('9:00:00 UTC')

      expect(Rails.logger).to receive(:info).with(/Running BirthdayCheckJob/)
      expect(Rails.logger).not_to receive(:info).with("Created birthday message for user #{user.id} (#{user.full_name})")

      BirthdayCheckJob.new.perform
      travel_back
    end
  end
end
