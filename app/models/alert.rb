class Alert < ApplicationRecord
  include Helpers::AlertHelper
  belongs_to :user, class_name: 'Login::User'
  enum :status, { created: 0, triggered: 1, deleted: 2 } 

  validates :coin_symbol, presence: true
  validates :target_price, presence: true

  after_create_commit :start_listening_coin
  before_save :sanitize_coin_symbol
  after_save :delete_cache_keys

  def to_h
    {
      "id" => id,
      "coin_symbol" => coin_symbol,
      "target_price" => target_price,
      "status" => status
    }
  end
  private

  def delete_cache_keys
    delete_all_cache_keys(user.id)
  end

  def sanitize_coin_symbol
    coin_symbol = coin_symbol.to_s.downcase
  end

  def start_listening_coin
    CoinSubscriber.perform_async(coin_symbol, id, target_price)
  end
end
