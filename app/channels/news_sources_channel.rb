class NewsSourcesChannel < ApplicationCable::Channel
  def subscribed
    stream_from 'news_sources_channel'
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end
end
