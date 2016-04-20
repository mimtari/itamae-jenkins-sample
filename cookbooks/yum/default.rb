execute "yum -y update" do
  command "yum -y update"
  only_if "yum list updates; test $? -eq 100"
end
