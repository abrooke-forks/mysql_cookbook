include_recipe "mysql::server"
include_recipe "mysql::ruby"
require 'mysql'


ruby_block "store_mysql_master_status" do
  block do
    node.set[:mysql][:master] = true
    unless node[:mysql][:server_id]
      node.set[:mysql][:server_id] = 1
    end
    begin
      m = Mysql.new("localhost", "root", node[:mysql][:server_root_password])
    rescue Mysql::Error => e
        Chef::Log.info "#{e.errno}"
        Chef::Log.info "#{e.error}"
    end
      m.query("show master status") do |row|
      row.each_hash do |h|
        node.set[:mysql][:master_file] = h['File']
        Chef::Log.info "Hfile #{h['file']}"
        node.set[:mysql][:master_position] = h['Position']
      end
    end
    Chef::Log.info "Storing database master replication status: #{node[:mysql][:master_file]} #{node[:mysql][:master_position]}"
    node.save
    #Look up slaves
    #slaves = search(:node, "role:#{node['mysql']['slave_role']} AND chef_environment:#{node.chef_environment}")
    #slaves.each{|slave|
    #  Chef::Log.info "#{slave.mysql.bind_address}"
    #  m.query("GRANT REPLICATION SLAVE ON *.* TO 'repl'@'#{slave.mysql.bind_address}' IDENTIFIED BY '#{node['mysql']['server_repl_password']}';")
    #}
    
  end
  # only execute if mysql is running
  only_if "pgrep 'mysqld$'"
  # subscribe to mysql service to catch restarts
  subscribes :create, resources(:service => "mysql")
end