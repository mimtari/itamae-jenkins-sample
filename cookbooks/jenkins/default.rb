ValidIpAddressRegex = "^(([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])\.){3}([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])$";
ValidHostnameRegex = "^(([a-zA-Z0-9]|[a-zA-Z0-9][a-zA-Z0-9\-]*[a-zA-Z0-9])\.)*([A-Za-z0-9]|[A-Za-z0-9][A-Za-z0-9\-]*[A-Za-z0-9])$";

UrlRegex = "(" + ValidIpAddressRegex + "|" + ValidHostnameRegex + ")"

url_regexp = Regexp.new(UrlRegex)

node.reverse_merge!({
  'jenkins' => {
    'master' => {
      'home' => '/var/lib/jenkins',
      'update_stable' => true,
      'repo_version' => 'rc',
      'url' => 'localhost',
      'port' => 8080,
      'prefix' => '',
      'user' => 'jenkins',
      'group' => 'jenkins'
    }
  }
})

node.validate! do
  {
    jenkins: {
      master: {
        home: match(/^(\/[a-zA-Z0-9\-_]+)+$/),
        update_stable: boolean,
        url: match(url_regexp),
        repo_version: match(/^(|stable|rc)$/),
        port: integer,
        prefix: match(/^(\/[a-zA-Z0-9\-_]+)*$/),
        user: match(/^[a-zA-Z0-9\-_]+$/),
        group: match(/^[a-zA-Z0-9\-_]+$/)
      },
    },
  }
end

master_user = node[:jenkins][:master][:user]
master_group = node[:jenkins][:master][:group]
master_home_dir = node[:jenkins][:master][:home]
repo_version = node[:jenkins][:master][:repo_version]

repo_version_prefix = repo_version.empty? ? "" : "-"
rpm_url = "http://pkg.jenkins-ci.org/redhat" + repo_version_prefix + repo_version
rpm_repo = rpm_url + "/jenkins.repo"
rpm_key = rpm_url + "/jenkins-ci.org.key"

master_log_dir='/var/log/jenkins/'
master_cache_dir='/var/cache/jenkins/'

package 'wget'
package "java-1.8.0-openjdk"

user master_user do
  action :create
end

group master_group do
  action :create
end

execute "add jenkins repo" do
  command  "wget -O /etc/yum.repos.d/jenkins.repo " + rpm_repo
  not_if "test -e /etc/yum.repos.d/jenkins.repo"
end

execute "import jenkins rpm key" do
  command "rpm --import " + rpm_key
  not_if "rpm -qa gpg-pubkey* | xargs rpm -qi | grep \"kohsuke.kawaguchi@sun.com\""
end

package 'jenkins' do
  action :install
end

[master_home_dir, master_log_dir, master_cache_dir].each do |dir|
  directory dir do
    user  master_user
    group master_group
    mode  '755'
  end
end

[master_home_dir, master_log_dir, master_cache_dir].each do |dir|
  execute "chown recursive " + dir do
    command "chown " + master_user + ":" + master_group + " -R " + dir
    only_if "find " + dir + " | sed -e 's/ /\\\\ /' | xargs stat --format=\"%U:%G\" | grep --invert-match \"^" + master_user + ":" + master_group + "$\""
    notifies :restart, "service[jenkins]", :delayed
  end
end

template "/etc/sysconfig/jenkins" do
  action :create
  mode '644'
  owner 'root'
  group 'root'
  notifies :restart, "service[jenkins]", :delayed
end

directory "/etc/nginx/conf.d" do
  action :create
  owner 'root'
  group 'root'
end

template "/etc/nginx/conf.d/jenkins.conf" do
  action :create
  mode '755'
  owner 'root'
  group 'root'
  notifies :reload, "service[nginx]"
end

template "/etc/firewalld/services/jenkins.xml" do
  action :create
  mode '644'
  owner 'root'
  group 'root'
  notifies :reload, "service[firewalld]"
end

template (master_home_dir + "/hudson.model.UpdateCenter.xml") do
  action :create
  mode '644'
  owner master_user
  group master_group
  source 'templates/jenkins_home/hudson.model.UpdateCenter.xml.erb'
  notifies :restart, "service[jenkins]", :delayed
end

service 'jenkins' do
  action [:enable, :start]
end
