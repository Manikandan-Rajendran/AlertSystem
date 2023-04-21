class AlertsController < ApplicationController
  include Helpers::AlertHelper

  DEFAULT_CACHE_TIME_IN_MINUTES = 10.minutes.to_i
  
  def create
    alert = Alert.new(create_alert_params)
    alert.user_id = @current_user.id
    alert.status = 'created'
    if alert.save
      delete_all_cache_keys
      render json: alert.to_h, status: :created
    else
      render json: alert.errors, status: :unprocessable_entity
    end
  end

  def destroy
    alert = Alert.where(user_id: @current_user.id, id: params[:id]).where.not(status: 'deleted').first
    if alert.blank?
      render json: "Alert Not Found", status: :not_found
      return
    end
    alert.deleted!
    delete_all_cache_keys
    CoinUnsubscriber.perform_async(alert.coin_symbol)
    render status: :no_content
  end

  def show
    params = index_params
    cache_key = get_cache_key(params)
    cached_response = REDIS_CACHE.get(cache_key)
    if cached_response.present?
      render json: cached_response
      return
    end
    status = params[:status] || Alert.statuses.except(:deleted).keys
    alerts = index_query(status).page(params[:current_page]).per(params[:per_page])
    total_pages = alerts.total_pages
    response = { alerts: alerts.map(&:to_h), filter: { status: params[:status], current_page: params[:current_page], per_page: params[:per_page], total_pages: total_pages } }
    REDIS_CACHE.setex(cache_key, DEFAULT_CACHE_TIME_IN_MINUTES, response.to_json)
    render json: response
  end

  private

  def index_params
    params[:current_page] = 1 if params[:current_page].blank?
    params[:per_page] =  10 if params[:per_page].blank?
    params.permit(:status, :current_page, :per_page)
  end

  def create_alert_params
    params.permit(:coin_symbol, :target_price)
  end
end