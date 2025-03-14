class User < ApplicationRecord
  has_many :messages, dependent: :destroy

  before_validation :set_timezone_from_coordinates

  validates :first_name, :last_name, :birthdate, :location, presence: true

  scope :with_birthday_today, -> { where("EXTRACT(MONTH FROM birthdate) = ? AND EXTRACT(DAY FROM birthdate) = ?", Time.current.month, Time.current.day) }

  def full_name
    "#{first_name} #{last_name}"
  end

  private

  def set_timezone_from_coordinates
    return unless timezone.blank? || location.present? && location_changed?

    begin
      latitude, longitude = Geocoder.search(location).first.coordinates
      timezone_obj = Timezone.lookup(latitude, longitude)
      self.timezone = timezone_obj.name if timezone_obj
    rescue => e
      self.timezone = 'UTC'
      Rails.logger.error("Failed to determine timezone for #{location}: #{e.message}")
    end
  end
end
