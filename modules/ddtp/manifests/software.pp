class ddtp::software {
	include ddtp::software::setup
	include ddtp::software::config
	include ddtp::software::ddtp-dinstall

	Class[ddtp::software::setup] -> Class[ddtp::software::config]
}

class ddtp::software::setup {
	# Create the ddtp user and directory
	file { '/srv':
		ensure => directory,
		owner => root,
		group => root,
		mode => 755,
	}

	file { '/org':
		ensure => '/srv'
	}

	file { "/srv/$server_name":
		ensure => directory,
		owner => ddtp,
		mode => 755,
	}

	user { 'ddtp':
		home => "/srv/$server_name",
		password => '*',
	}

	package { ['libdbd-pg-perl', 'libtext-diff-perl', 'libwww-perl', 'libmime-tools-perl']: }
	package { 'bzip2': }
	package { 'gnuplot-nox': }

	exec { "/usr/bin/git clone git://git.debian.org/git/debian-l10n/ddtp.git /srv/$server_name":
		user => ddtp,
		creates => "/srv/$server_name/.git",
		cwd => "/srv/$server_name",
		require => File["/srv/$server_name"],
	}
}

class ddtp::software::config {
	# pg_service file so everyone can login to database
	file { "/srv/$server_name/.pg_service.conf":
		content => template('ddtp/pg_service.conf'),
		owner => ddtp,
	}

	# Create needed directories
	file { ["/srv/$server_name/log", "/srv/$server_name/gnuplot"]:
		ensure => directory,
		owner => ddtp,
		mode => 644,
	}

	# DDTP CGI script
	file { '/var/www/ddtp/ddt.cgi':
		ensure => "/srv/$server_name/ddt.cgi",
	}

	# DDTSS CGI script
	file { '/var/www/ddtp/ddtss':
		ensure => directory,
		owner => ddtp,
	}

	file { '/var/www/ddtp/ddtss/index.cgi':
		ensure => "/srv/$server_name/ddtss/ddtss-cgi",
	}
}

class ddtp::software::ddtp-dinstall {
	file { '/srv/ddtp-dinstall':
		ensure => directory,
		owner => ddtp,
	}

	# Link must exist, though doesn't need to point anywhere
	file { '/srv/ddtp-dinstall/to-dak':
		ensure => link,
		target => 'x',
		replace => false,
	}

	# Special user for dak to login
	user { 'ddtp-dak':
		home => "/home/ddtp-dak",
		password => "*",
	}

	file { "/home/ddtp-dak":
		ensure => directory,
		owner => "ddtp-dak",
		mode => 755,
	}

	# This is the directory where the authorized_keys file must go to allow dak to login
	file { "/home/ddtp-dak/.ssh":
		ensure => directory,
		owner => "ddtp-dak",
		mode => 700,
	}

	# Sample file for the correct options...
	file { "/home/ddtp-dak/.ssh/authorized_keys":
		owner => "ddtp-dak",
		mode => 600,
		replace => false,
		content => 'command="/usr/bin/rsync --server --sender -logDtpr . /srv/ddtp-dinstall/to-dak/.",from="ries.debian.org,128.148.34.103,franck.debian.org,128.148.34.3",no-agent-forwarding,no-port-forwarding,no-pty,no-X11-forwarding ssh-rsa AAA...',
	}
}
