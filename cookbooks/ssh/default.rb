node.reverse_merge!({
  'sshd' => {
    'port' => 22
  }
})

node.validate! do
  {
    sshd: {
      port: integer,
    },
  }
end

service "sshd" do
  action [:enable, :start]
end

template "/etc/ssh/sshd_conf" do
  action :create
  notifies :reload, "service[sshd]"
end
