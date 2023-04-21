require 'websocket-client-simple'

class CoinUnsubscriber
  include Sidekiq::Worker
  sidekiq_options queue: :websocket
  
  def perform(coin_symbol)
    if Alert.created.where(coin_symbol: coin_symbol).count == 0
      BINANCE_WEB_SOCKET_CONNECTION.unsubscribe(coin_symbol)
      Rails.logger.info "Unsubscribed Coin #{coin_symbol}"
    end
  end
end