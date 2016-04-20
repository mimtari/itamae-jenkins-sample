directory "/etc/yum.repos.d" do
  action :create
  owner 'root'
  group 'root'
end

remote_file "/etc/yum.repos.d/nginx.repo" do
  action :create
  mode '644'
  owner 'root'
  group 'root'
end

package 'nginx' do
  action :install
  options '--enablerepo=nginx'
end

service 'nginx' do
  action [:enable, :start]
end
