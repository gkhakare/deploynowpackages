#
# Cookbook Name:: deploynowpackages
# Recipe:: default
#
# Copyright 2015, Opex Software
#
# All rights reserved - Do Not Redistribute
#

# Download and untar/unzip the specified package in the /tmp/deploynow/cookbooks dir
node["deploynowpackages"]["packages"].each do |package|

  unless package.is_a? Hash
    raise "DeployNow : Package [#{package}] is required to be a hash"
  end

  if not package.has_key? "download_url_linux"
    raise "DeployNow : Package [#{package}] has no 'download_url_linux'"
  end

  if not package.has_key? "download_url_windows"
    raise "DeployNow : Package [#{package}] has no 'download_url_windows'"
  end

  if not package.has_key? "zip_file_name_linux"
    raise "DeployNow : Package [#{package}] has no 'zip_file_name_linux'"
  end

  if not package.has_key? "zip_file_name_windows"
    raise "DeployNow : Package [#{package}] has no 'zip_file_name_windows'"
  end

  if not package.has_key? "unzipped_name"
    raise "DeployNow : Package [#{package}] has no 'unzipped_name'"
  end

  if not package.has_key? "package_name"
    raise "DeployNow : Package [#{package}] has no 'package_name'"
  end
 
	actual_download_url = ""
	if platform?('windows')
		directory node['deploynowpackages']['packages_home_win'] do
			mode '0755'
			action :create
		end
		package_download_file = "#{node['deploynowpackages']['packages_home_win']}#{package['zip_file_name_windows']}"
		actual_download_url = package['download_url_windows']
	else
		directory node['deploynowpackages']['packages_home_linux'] do
			mode '0755'
			action :create
		end
		package_download_file = "#{node['deploynowpackages']['packages_home_linux']}#{package['zip_file_name_linux']}"
		actual_download_url = package['download_url_linux']
	end

	remote_file package_download_file do
		source actual_download_url
		mode '0755'
	end

	if platform?('windows')
		powershell_script 'unzip package' do
  		code <<-EOH
	 			$shell = new-object -com shell.application
	  			$zip = $shell.NameSpace("#{package_download_file}")
	  			foreach($item in $zip.items())
	  			{
	  			$shell.Namespace("#{node['deploynowpackages']['packages_home_win']}").copyhere($item)
	  			}
	  		EOH
		end	

		batch 'renaming unzipped files' do
		code <<-EOH
				rename #{node['deploynowpackages']['packages_home_win']}#{package['unzipped_name']} #{package['package_name']}
			EOH
		end
	else
		bash 'extract_package' do
			code <<-EOH
				cd #{node["deploynowpackages"]["packages_home_linux"]}
				tar -zxf #{package['zip_file_name_linux']}
				mv #{package['unzipped_name']} #{package['package_name']}
			EOH
		end
	end
end
