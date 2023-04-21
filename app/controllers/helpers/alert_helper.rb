module Helpers
  module AlertHelper
    def index_query(status)
      @current_user.alerts.where(status: status)
    end

    def delete_all_cache_keys(user_id = nil)
      user_id ||= @current_user.id
      keys = REDIS_CACHE.keys cache_key_prefix(user_id) + "*"
      REDIS_CACHE.del(*keys) unless keys.empty?
    end

    def get_cache_key(params)
      cache_key_prefix(@current_user.id) + params[:current_page].to_s + params[:per_page].to_s + params[:status].to_s
    end

    def cache_key_prefix(user_id)
      "AlertsController::Cache::" + user_id.to_s
    end
  end
end