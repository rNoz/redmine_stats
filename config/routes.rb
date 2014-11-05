# Plugin's routes
# See: http://guides.rubyonrails.org/routing.html

#get 'stats', :to => 'stats#index'
match "stats",  to: redirect("stats/all")
get 'stats/:time_filter', :to => 'stats#index'
