  desc 'Clear image and redis caches'
  task wipe_caches: :environment do
    begin
      NewsSource.clear_all_caches
      REDIS.del("newsfeed")
      StoryImage.find_each(&:purge)
      StoryVideo.find_each(&:purge)
      NewsSource.update_all(:last_scanned_at=>nil)
    rescue Exception=>e
      puts e.message
    end 
  end 