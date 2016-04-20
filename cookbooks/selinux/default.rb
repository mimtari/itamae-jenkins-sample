node.reverse_merge!({
  'selinux' => {
    'enabled' => true,
    'status' => 'enforcing'
  }
})

node.validate! do
  {
    selinux: {
      enabled: boolean,
      status: match(/^(permissive|enforcing)$/),
    }
  }
end

if node[:selinux][:enabled]
  execute "set selinux status" do
    command "setenforce #{node[:selinux][:status].capitalize}"
    not_if "getenforce | grep --ignore-case #{node[:selinux][:status]}"
  end
else
  execute "set selinux disabled" do
    command "setenforce 0"
    only_if "selinuxenabled"
  end
end
