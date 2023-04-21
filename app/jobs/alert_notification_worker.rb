require 'mail'

class AlertNotificationWorker
  include Sidekiq::Worker
   sidekiq_options queue: :default

  def perform(alert_id, symbol, price)
    symbol = symbol.upcase
    alert = Alert.created.where(id: alert_id).first
    return if alert.blank?
    Rails.logger.info "Sending notification to #{alert.user.email} for #{symbol} at #{price}"
    alert.triggered!
    Rails.logger.info "updated alert data #{alert.to_h}"
    # Mail.deliver do
    #   to user_email
    #   from 'pricealertapp@example.com'
    #   subject "Target Price Alert for #{symbol}"
    #   body "The #{symbol} price has reached your target price of #{price.to_i}."
    # end
  end
end
