# require 'jobs/complete_event_job'
namespace :ceti_tasks do
  desc "TODO"
  task complete_events_task: :environment do
  	#Notification.create(user_id: 34,act_user_id: 34, event_id: 0, n_type: :message, read:false)
  	CompleteEventJob.set(queue: :default).perform_later()
  end

end
