Services = ["RH-Satellite-6", "amanda-client", "bacula", "bacula-client", "dhcp", "dhcpv6", "dhcpv6-client", "dns", "freeipa-ldap", "freeipa-ldaps", "freeipa-replication", "ftp", "high-availability", "http", "https", "imaps", "ipp", "ipp-client", "ipsec", "iscsi-target", "kerberos", "kpasswd", "ldap", "ldaps", "libvirt", "libvirt-tls", "mdns", "mountd", "ms-wbt", "mysql", "nfs", "ntp", "openvpn", "pmcd", "pmproxy", "pmwebapi", "pmwebapis", "pop3s", "postgresql", "proxy-dhcp", "radius", "rpc-bind", "rsyncd", "samba", "samba-client", "smtp", "ssh", "telnet", "tftp", "tftp-client", "transmission-client", "vdsm", "vnc-server", "wbem-https"]

node.reverse_merge!({
  'firewall' => {
    'public' => {
      'services' => ['http', 'https', 'ssh']
    }
  }
})

node.validate! do
  {
    firewall: {
      public: {
        services: array_of(string)
      },
    },
  }
end

service "firewalld" do
  action [:enable, :start]
end

public_services = node[:firewall][:public][:services]

# ensure ssh service
public_services.push('ssh') unless public_services.include?('ssh')
remove_public_services = Services - public_services

# remove
remove_public_services.each do |service|
  execute "firewall-cmd --zone public --remove-service #{service} --permanent" do
    only_if "firewall-cmd --zone=public --query-service=#{service}"
    notifies :reload, "service[firewalld]"
  end
end

# add
public_services.each do |service|
  execute "firewall-cmd --zone public --add-service #{service} --permanent" do
    not_if "firewall-cmd --zone=public --query-service=#{service}"
    notifies :reload, "service[firewalld]"
  end
end
