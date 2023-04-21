require 'websocket-client-simple'

class CoinSubscriber
  include Sidekiq::Worker
  sidekiq_options queue: :websocket
  
  def perform(coin_symbol, alert_id, target_price)
    BINANCE_WEB_SOCKET_CONNECTION.subscribe(coin_symbol, alert_id, target_price)
    Rails.logger.info "Subscribed to #{coin_symbol} for #{target_price}"
  end
end