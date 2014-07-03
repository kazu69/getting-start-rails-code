# -*- coding: utf-8 -*-

# Our own variable where we deploy this app to
# add
deploy_to = '/home/vagrant'

rails_env = ENV['RAILS_ENV'] || 'production'

# add
current_path = "#{deploy_to}/#{rails_env}/current"
shared_path = "#{deploy_to}/#{rails_env}/shared"
shared_bundler_gems_path = "#{shared_path}/bundle"

# worker
worker_processes 2

# socket
listen '/tmp/unicorn.sock'
# pid 'tmp/pids/unicorn.pid'
# add
pid "#{current_path}/tmp/pids/unicorn.pid"

check_client_connection false

# Help ensure your application will always spawn in the symlinked
# "current" directory that Capistrano sets up.
# add
working_directory current_path

# nuke workers after 30 seconds instead of 60 seconds (the default)
timeout 30

# listen port
listen 3000, :tcp_nopush => true

# log
# log = 'var/log/rails/unicorn.log'
# stderr_path File.expand_path('log/unicorn.log', ENV['RAILS_ROOT'])
# stdout_path File.expand_path('log/unicorn.log', ENV['RAILS_ROOT'])

# By default, the Unicorn logger will write to stderr.
# Additionally, some applications/frameworks log to stderr or stdout,
# so prevent them from going to /dev/null when daemonized here:
# add
stderr_path "#{shared_path}/log/unicorn.stderr.log"
stdout_path "#{shared_path}/log/unicorn.stdout.log"

# graceful restart
# ワーカープロセスをforkする直前にあるフックポイント。
before_fork do |server, worker|
  defined?(ActiveRecord::Base) and
    ActiveRecord::Base.connection.disconnect!

  # The following is only recommended for memory/DB-constrained
  # installations.  It is not needed if your system can house
  # twice as many worker_processes as you have configured.
  #
  # # This allows a new master process to incrementally
  # # phase out the old master process with SIGTTOU to avoid a
  # # thundering herd (especially in the "preload_app false" case)
  # # when doing a transparent upgrade.  The last worker spawned
  # # will then kill off the old master process with a SIGQUIT.
  old_pid = "#{server.config[:pid]}.oldbin"
  if old_pid != server.pid
    begin
      sig = (worker.nr + 1) >= server.worker_processes ? :QUIT : :TTOU
      Process.kill(sig, File.read(old_pid).to_i)
    rescue Errno::ENOENT, Errno::ESRCH
    end
  end
end

# combine Ruby 2.0.0dev or REE with "preload_app true" for memory savings
# http://rubyenterpriseedition.com/faq.html#adapt_apps_for_cow
preload_app true
GC.respond_to?(:copy_on_write_friendly=) and
  GC.copy_on_write_friendly = true

# ワーカープロセスをfork後、いくつかの必要な処理を挟んだところにあるフックポイント。
after_fork do |server, worker|
  # worker.user('deployer', 'deployer') if Process.euid == 0
  # per-process listener ports for debugging/admin/migrations
  # addr = "127.0.0.1:#{9293 + worker.nr}"
  # server.listen(addr, :tries => -1, :delay => 5, :tcp_nopush => true)
  # the following is *required* for Rails + "preload_app true",
  defined?(ActiveRecord::Base) and
    ActiveRecord::Base.establish_connection

  # if preload_app is true, then you may also want to check and
  # restart any other shared sockets/descriptors such as Memcached,
  # and Redis.  TokyoCabinet file handles are safe to reuse
  # between any number of forked children (assuming your kernel
  # correctly implements pread()/pwrite() system calls)
  # Reconnect memcached
  # Rails.cache.reset
end

# add
# 新しいマスタプロセスを作る(reexec)際のexec()が実行される直前にあるフックポイント
# before_exec do |server|
#   paths = (ENV['PATH'] || '').split(File::PATH_SEPARATOR)
#   paths.unshift "#{shared_bundler_gems_path}/bin"
#   ENV['PATH'] = paths.uniq.join(File::PATH_SEPARATOR)
#   ENV['GEM_HOME'] = ENV['GEM_PATH'] = shared_bundler_gems_path
#   ENV['BUNDLE_GEMFILE'] = "#{current_path}/Gemfile"
# end

before_exec do |server|
  ENV['BUNDLE_GEMFILE'] = "#{current_path}/Gemfile"
end
