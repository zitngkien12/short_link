class ShortenedUrl < ApplicationRecord
  MAX_URL_LENGTH = 2_048
  SHORT_CODE_LENGTH = 6
  SHORT_CODE_FORMAT = /\A[a-z0-9]{6}\z/

  validates :original_url,
            presence: true,
            length: { maximum: MAX_URL_LENGTH }

  validates :short_code,
            presence: true,
            uniqueness: true,
            format: { with: SHORT_CODE_FORMAT },
            length: { is: SHORT_CODE_LENGTH }

  validate :original_url_must_be_http_or_https

  def full_short_url
    "#{ENV.fetch('DEFAULT_HOST', 'http://localhost:3000')}/#{short_code}"
  end

  private

  def original_url_must_be_http_or_https
    return if original_url.blank?

    uri = URI.parse(original_url)
    return if %w[http https].include?(uri.scheme) && uri.host.present?

    errors.add(:original_url, "must be a valid HTTP or HTTPS URL")
  rescue URI::InvalidURIError
    errors.add(:original_url, "must be a valid HTTP or HTTPS URL")
  end
end