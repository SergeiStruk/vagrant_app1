rails_env = ENV['RAILS_ENV'] || 'production'
rails_root = ENV['RAILS_ROOT'] || "/var/www/testing/current"

God.watch do |w|
  w.name = "unicorn"
  w.interval = 30.seconds # default
  # unicorn needs to be run from the rails root
  w.start = "cd #{rails_root} && RAILS_ENV=production bundle exec /usr/local/bin/unicorn_rails -c #{rails_root}/config/unicorn.rb"

  # QUIT gracefully shuts down workers
  w.stop = "ps ax|grep -i unicorn |awk '{print $1}'|xargs kill -9"

  # USR2 causes the master to re-create itself and spawn a new worker pool
  w.restart = "ps ax|grep -i unicorn |awk '{print $1}'|xargs kill -9 && cd #{rails_root} && bundle exec /usr/local/bin/unicorn_rails -c #{rails_root}/config/unicorn.rb"

  w.start_grace = 10.seconds
  w.restart_grace = 10.seconds
  w.pid_file = "#{rails_root}/tmp/pids/unicorn.pid"

#  w.uid = 'git'
#  w.gid = 'git'

  w.behavior(:clean_pid_file)

  w.start_if do |start|
    start.condition(:process_running) do |c|
      c.interval = 5.seconds
      c.running = false
    end
  end 
          
  w.restart_if do |restart|
    restart.condition(:memory_usage) do |c|
      c.above = 300.megabytes
      c.times = [3, 5] # 3 out of 5 intervals
    end
             
    restart.condition(:cpu_usage) do |c|
      c.above = 50.percent 
      c.times = 5
    end
  end

  # lifecycle
  w.lifecycle do |on|
    on.condition(:flapping) do |c|
      c.to_state = [:start, :restart]
      c.times = 5 
      c.within = 5.minute
      c.transition = :unmonitored
			c.retry_in = 10.minutes
      c.retry_times = 5
      c.retry_within = 2.hours
    end
  end
end
                                                                                                                                                                                                                    
