if ENV['SOCKET_ENABLED']
  require 'websocket-client-simple'

  class BinanceWebSocketClient
    def initialize
      @websocket = nil
      @subscriptions = {}
      @quote_asset = "usdt".freeze
    end

    def connect
      @websocket = WebSocket::Client::Simple.connect('wss://stream.binance.com:9443/ws')
      @websocket.on(:message) { |msg| BinanceWebSocketClient.handle_message(msg) }
      @websocket.on(:error) { |err| BinanceWebSocketClient.handle_error(err) }
      @websocket.on(:close) { |code, reason| BinanceWebSocketClient.handle_close(code, reason) }
      @websocket.on(:open) { BinanceWebSocketClient.handle_open }
      set_pong
    end

    def set_pong
      pong_interval = 300
      Thread.new do
        loop do
          sleep pong_interval
          BINANCE_WEB_SOCKET_CONNECTION.socket.send('{"pong":' + Time.now.to_i.to_s + '}') unless BINANCE_WEB_SOCKET_CONNECTION.socket.blank?
        end
      end
    end

    def socket
      @websocket
    end
  
    def subscriptions
      @subscriptions
    end

    def subscribe(symbol, alert_id, target_price, force_subscribe: false)
      # Create subscription payload
      subscription_payload = {
        'method': 'SUBSCRIBE',
        'params': ["#{symbol.downcase}#{@quote_asset}@trade"],
        'id': alert_id
      }.to_json

      # Add the alert to the corresponding symbol subscription
      @subscriptions[symbol] ||= { 'alerts': {}, 'websocket_subscription': nil }.with_indifferent_access
      @subscriptions[symbol][:alerts][alert_id] = { 'target_price': target_price}.with_indifferent_access

      # If there's no existing subscription for the symbol, create a new one
      if @subscriptions[symbol]['websocket_subscription'].nil? || force_subscribe
        @websocket.send(subscription_payload)
        @subscriptions[symbol]['websocket_subscription'] = true
      end
    end

    def unsubscribe(symbol)
      subscription_payload = {
        'method': 'UNSUBSCRIBE',
        'params': ["#{symbol.downcase}#{@quote_asset}@trade"]
      }
      BINANCE_WEB_SOCKET_CONNECTION.socket.send(subscription_payload)
      @subscriptions.delete(symbol)
    end

    def self.handle_message(msg)
      data = JSON.parse(msg.data)
      Rails.logger.info "Recieved data #{data}"
      # Removing quote_asset from symbol to validate the conditions
      symbol = data['s'][0...-4].to_s.downcase rescue "INVALID RESPONSE"
      if symbol == "INVALID RESPONSE"
        Rails.logger.error "Unrecoginized message #{data}"
        return
      end
      trade_price = data['p'].to_i
      subscriptions = BINANCE_WEB_SOCKET_CONNECTION.subscriptions

      # Check if there are any alerts for this symbol
      if subscriptions.key?(symbol)
        subscriptions[symbol][:alerts].each do |alert_id, alert_data|
          if trade_price == alert_data[:target_price].to_i
            Rails.logger.info "Enqueuing alert notifier for #{alert_id}"
            AlertNotificationWorker.perform_async(alert_id, symbol, trade_price)
            subscriptions[symbol]['alerts'].delete(alert_id)
          end
        end
      end

      if subscriptions[symbol]['alerts'].empty?
        BINANCE_WEB_SOCKET_CONNECTION.unsubscribe(symbol)
      end
    end

    def self.handle_error(err)
      Rails.logger.error "Error Occurred #{err}"
      BINANCE_WEB_SOCKET_CONNECTION.socket.close
    end

    def self.handle_close(code, reason)
      Rails.logger.error "Connection closing with #{code} and #{reason}.. Retrying connection again"
      Rails.logger.info "Subscriptions before closing #{BINANCE_WEB_SOCKET_CONNECTION.subscriptions}"
      BINANCE_WEB_SOCKET_CONNECTION.connect
    end

    def self.handle_open
      Rails.logger.info "Connection opened successfully"
      subscriptions = BINANCE_WEB_SOCKET_CONNECTION.subscriptions
      Rails.logger.info "Subscriptions #{BINANCE_WEB_SOCKET_CONNECTION.subscriptions}"
      subscriptions.each do|symbol, subscription_payload|
        subscriptions[symbol][:alerts].each do |alert_id, alert_data|
          BINANCE_WEB_SOCKET_CONNECTION.subscribe(symbol, alert_id, alert_data[:target_price], force_subscribe: true)
          break
        end
      end
    end
  end

  BINANCE_WEB_SOCKET_CONNECTION = BinanceWebSocketClient.new
  BINANCE_WEB_SOCKET_CONNECTION.connect
end