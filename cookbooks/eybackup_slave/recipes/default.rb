#
# Cookbook Name:: eybackup_slave
# Recipe:: default
#

# database is mysql? (EY Cloud already sets up eybackup on the slave for postgres)
unless node[:engineyard][:environment][:db_stack_name][/mysql/i]
  raise "This recipe is for environments with a MySQL database"
end

# backups disabled?
if node[:backup_window].to_s == "0"
  raise "Backups are disabled for this environment"
end

# find database slave node
db_slave = node[:engineyard][:environment][:instances].find{|i| i[:role][/db_slave/]}

# calculate hour
interval = node[:backup_interval]
hour = interval.to_i == 24 ? "1" : (interval ? "*/#{interval}" : "1")

if db_slave
  # remove db master cronjob
  if node[:instance_role][/db_master/]
    cron "mysql" do
      action :delete
    end
  end

  # setup cronjob on db slave
  if node[:engineyard][:this] == db_slave[:id]
    cron "mysql" do
      minute "10"
      hour hour
      day "*"
      month "*"
      weekday "*"
      command "/usr/local/ey_resin/bin/eybackup -e mysql >> /var/log/eybackup.log"
    end  
  end
else
  Chef::Log.info "There is no database slave available, leaving eybackup cronjob on the database master"
end
