### Cache setup
Redis stores the list of caches by vendor under `'newsfeed_caches'`
```ruby
> REDIS.smembers("newsfeed_caches")
["cached_stories:pc_gamer",
 "cached_stories:ars_technica",
 "cached_stories:al_jazeera",
 "cached_stories:new_york_times"]
```

Each key stores a json string with a key val of
`{link_md5_hash=>story_json}`
```ruby
> REDIS.hkeys("cached_stories:npr")
  ["260adb7f4fbfefdaafea2316ec4417e8",
   "409229f8e90fc238ee282ab6c51e735a",
   "4d4105f3e817558da5711acae378357d",
   "889df46d815769bad2a07675d1677cb7"]

>3.2.1 :004 > REDIS.hget("cached_stories:npr", "260adb7f4fbfefdaafea2316ec4417e8") 
"{\"source\":\"npr\",\"link\":...}"
```

Each cached story has a cache_time field of of int time
any time a story's cache is pulled this field is updated to current time
caches with a time older than 2 days get pruned