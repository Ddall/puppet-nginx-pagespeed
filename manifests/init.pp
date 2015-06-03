class nginx_pagespeed (
    $module_home = '/usr/local/src',
    $nginx_version = '1.6.3', # check this http://nginx.org/en/download.html
    $ngx_pagespeed_version = 'release-1.9.32.3-beta', # check this https://developers.google.com/speed/pagespeed/module/build_ngx_pagespeed_from_source
    $google_psol_version = '1.9.32.3'
){

  # DEPENDANCIES
  $deps = [
    'wget',
    'zlib1g-dev',
    'libgd-dev',
    
  ]
  ensure_packages($deps)

  # GROUP & USER
  group { "www-data" :
    ensure  =>  present,
    gid     => "33"
  }

  user { "www-data" :
    ensure =>   present,
    uid    =>   "33",
    gid    =>   "www-data",
    shell  =>   "/usr/sbin/nologin",
    managehome  =>  false,
  }

  # DOWNLOAD & INSTALL
  # SEE https://developers.google.com/speed/pagespeed/module/build_ngx_pagespeed_from_source
  # SEE http://wiki.nginx.org/InstallOptions
  wget::fetch { "download ngx_pagespeed":
    source      => "https://github.com/pagespeed/ngx_pagespeed/archive/${ngx_pagespeed_version}.zip",
    destination => "${module_home}/${ngx_pagespeed_version}.zip",
    timeout     => 0,
    verbose     => false,
  } ->
  exec { "unzip ngx_pagespeed":
    command => "/usr/bin/unzip -d ${module_home}/ ${module_home}/${ngx_pagespeed_version}.zip",
    creates => "${module_home}/ngx_pagespeed-${ngx_pagespeed_version}",
  } ->
  wget::fetch { "download google psol":
    source      => "https://dl.google.com/dl/page-speed/psol/${google_psol_version}.tar.gz",
    destination => "${module_home}/ngx_pagespeed-${ngx_pagespeed_version}/${google_psol_version}.tar.gz",
    timeout     => 0,
    verbose     => false,
  } ->
  exec { "untar google psol":
    command => "/bin/tar zxf ${module_home}/ngx_pagespeed-${ngx_pagespeed_version}/${google_psol_version}.tar.gz -C ${module_home}/ngx_pagespeed-${ngx_pagespeed_version}",
    creates => "${module_home}/ngx_pagespeed-${ngx_pagespeed_version}/psol"
  } ->
  wget::fetch {"download nginx":
    source      => "http://nginx.org/download/nginx-${nginx_version}.tar.gz",
    destination => "${module_home}/nginx-${nginx_version}.tar.gz",
    timeout     => 0,
    verbose     => true,
  } ->
  exec { 'untar nginx':
    command => "/bin/tar zxf ${module_home}/nginx-${nginx_version}.tar.gz -C ${module_home}",
    creates => "${module_home}/nginx-${nginx_version}",
  }->
  # YOU SHOULD RUN make clean in NGX DIRECTORY after making changes to configure options
  exec { 'configure nginx':
      cwd     =>  "${module_home}/nginx-${nginx_version}",
      command =>  "${module_home}/nginx-${nginx_version}/configure --add-module=${module_home}/ngx_pagespeed-${ngx_pagespeed_version} --prefix=/usr/share/nginx --sbin-path=/usr/sbin/nginx --conf-path=/etc/nginx/nginx.conf --pid-path=/var/run/nginx.pid --lock-path=/var/lock/nginx.lock --error-log-path=/var/log/nginx/error.log --with-http_image_filter_module --with-http_ssl_module --http-log-path=/var/log/nginx/access.log --user=www-data --group=www-data",
      creates =>  "${module_home}/nginx-${nginx_version}/Makefile",
  }->
  exec { 'make nginx':
    cwd     =>  "${module_home}/nginx-${nginx_version}",
    command =>  "/usr/bin/make --directory=${module_home}/nginx-${nginx_version}",
    creates =>  "${module_home}/nginx-${nginx_version}/objs/nginx",
  }->
  exec { 'make install nginx':
    cwd     =>  "${module_home}/nginx-${nginx_version}",
    command =>  "/usr/bin/make install --directory=${module_home}/nginx-${nginx_version}",
    creates =>  "/usr/local/nginx/sbin/nginx",
  }->
  notify { "NGINX-${nginx_version} + MOD_PAGESPEED-${ngx_pagespeed_version} ": }
}