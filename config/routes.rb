Rails.application.routes.draw do
  resources :news_sources do
    collection do
      get :get_news
      get :rss
      post :update_layout
    end
  end
  
  get 'news_sources/rss_feed/:slug', :to=>'news_sources#rss_feed'
  
  get 'news_sources/:source_name/story/:story_hash', :to=>'news_sources#get_story'
  mount ActionCable.server => '/cable'
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
end
