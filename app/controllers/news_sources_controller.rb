class NewsSourcesController < ApplicationController
  include ActiveStorage::SetCurrent
  before_action :set_news_source, only: [:show, :update, :destroy]

  # GET /news_sources
  def index
    render :json=>REDIS.call('get', 'newsfeed')
  end

  def get_news
    NewsSourcesChannel.broadcast_to('news_sources_channel', JSON.parse(REDIS.call('get', 'newsfeed')))
    render :head=>:ok
  end
  
  def get_story
    source = NewsSource.find_by_slug(params[:source_name])
    render :json=>REDIS.hget(source.cache_key, params[:story_hash])
  end
  #
  # # GET /news_sources/1
  # def show
  #   render json: @news_source
  # end
  #
  # # POST /news_sources
  # def create
  #   @news_source = NewsSource.new(news_source_params)
  #
  #   if @news_source.save
  #     render json: @news_source, status: :created, location: @news_source
  #   else
  #     render json: @news_source.errors, status: :unprocessable_entity
  #   end
  # end
  #
  # # PATCH/PUT /news_sources/1
  # def update
  #   if @news_source.update(news_source_params)
  #     render json: @news_source
  #   else
  #     render json: @news_source.errors, status: :unprocessable_entity
  #   end
  # end
  #
  # # DELETE /news_sources/1
  # def destroy
  #   @news_source.destroy
  # end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_news_source
      @news_source = NewsSource.find(params[:id])
    end

    # Only allow a trusted parameter "white list" through.
    def news_source_params
      params.require(:news_source).permit(:name, :feed_url)
    end
end
