require 'rails_helper'

RSpec.describe User, type: :model do
  describe 'associations' do
    it { should have_many(:messages).dependent(:destroy) }
  end

  describe 'validations' do
    it { should validate_presence_of(:first_name) }
    it { should validate_presence_of(:last_name) }
    it { should validate_presence_of(:birthdate) }
    it { should validate_presence_of(:location) }
    it { should validate_presence_of(:timezone) }
    it { should validate_inclusion_of(:timezone).in_array(ActiveSupport::TimeZone.all.map(&:name)) }
  end

  describe '#full_name' do
    it 'returns the full name of the user' do
      user = build(:user, first_name: 'John', last_name: 'Doe')
      expect(user.full_name).to eq('John Doe')
    end
  end

  describe '#birthday_today?' do
    it 'returns true if today is the user\'s birthday in their timezone' do
      # Create a user with today's date as birthday
      today = Time.current.to_date
      user = build(:user, birthdate: today.change(year: 1990), timezone: 'UTC')

      # Mock Time.current to return a fixed time
      allow(Time).to receive(:current).and_return(today.to_time)

      expect(user.birthday_today?).to be true
    end

    it 'returns false if today is not the user\'s birthday' do
      # Create a user with tomorrow's date as birthday
      today = Time.current.to_date
      tomorrow = today + 1.day
      user = build(:user, birthdate: tomorrow.change(year: 1990), timezone: 'UTC')

      # Mock Time.current to return a fixed time
      allow(Time).to receive(:current).and_return(today.to_time)

      expect(user.birthday_today?).to be false
    end
  end

  describe '#nine_am_in_timezone?' do
    it 'returns true if it\'s 9am in the user\'s timezone' do
      user = build(:user, timezone: 'UTC')

      # Mock Time.current to return 9:01am UTC
      nine_am = Time.new(2023, 1, 1, 9, 1, 0, '+00:00')
      allow(Time).to receive(:current).and_return(nine_am)

      expect(user.nine_am_in_timezone?).to be true
    end

    it 'returns false if it\'s not 9am in the user\'s timezone' do
      user = build(:user, timezone: 'UTC')

      # Mock Time.current to return 10:01am UTC
      ten_am = Time.new(2023, 1, 1, 10, 1, 0, '+00:00')
      allow(Time).to receive(:current).and_return(ten_am)

      expect(user.nine_am_in_timezone?).to be false
    end
  end

  describe '#should_send_birthday_message?' do
    it 'returns true if it\'s the user\'s birthday and it\'s 9am in their timezone' do
      user = build(:user, timezone: 'UTC')

      allow(user).to receive(:birthday_today?).and_return(true)
      allow(user).to receive(:nine_am_in_timezone?).and_return(true)

      expect(user.should_send_birthday_message?).to be true
    end

    it 'returns false if it\'s not the user\'s birthday' do
      user = build(:user, timezone: 'UTC')

      allow(user).to receive(:birthday_today?).and_return(false)
      allow(user).to receive(:nine_am_in_timezone?).and_return(true)

      expect(user.should_send_birthday_message?).to be false
    end

    it 'returns false if it\'s not 9am in the user\'s timezone' do
      user = build(:user, timezone: 'UTC')

      allow(user).to receive(:birthday_today?).and_return(true)
      allow(user).to receive(:nine_am_in_timezone?).and_return(false)

      expect(user.should_send_birthday_message?).to be false
    end
  end

  describe '#create_birthday_message_if_needed' do
    it 'creates a birthday message if none exists for today' do
      user = create(:user)

      expect {
        user.create_birthday_message_if_needed
      }.to change(Message.birthday, :count).by(1)

      message = user.messages.last
      expect(message.message_type.to_sym).to eq(:birthday)
      expect(message.status).to eq('pending')
      expect(message.retry_count).to eq(0)
    end

    it 'does not create a birthday message if one already exists for today' do
      user = create(:user)
      create(:message, :birthday, user: user)

      expect {
        user.create_birthday_message_if_needed
      }.not_to change(Message.birthday, :count)
    end
  end
end
