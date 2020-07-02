# system configuration
#
namespace eval system::config {

    global config config_db editor highlight_groups

    proc load_config {} {
	variable config
	sqlite3 config_db $::load_path/etc/system.cfg
	config_db eval { create table if not exists core_config (config_id integer primary key, path text, value text, session text)}

	set select [ config_db eval { select path, value, session from core_config } ]

	if { $select != "" } {
	    foreach { key value } $select {
		dict set config $key $value
	    }
	} else {
	    dict set config magento_dir ""
	    dict set config session {}
	}
    }

    proc save_config {} {
	variable config
	dict for { key value} $config {
	    if { [ config_db exists { select config_id from core_config where path like "%$key%" }] } {
		config_db eval { update core_config set value = $value where path like "%$key%"}
	    } else {
		config_db eval { insert into core_config (path, value) values ($key, $value)}
	    }
	}
    }

    proc get_magento_dir {} {
	variable config
	return [ dict get $config magento_dir ]
    }

    proc save_session {session} {
	variable config
	dict set config session $session
	save_config
    }

    proc restore_session {} {
	variable config
	return [dict get $config session]
    }

    proc select_magento_dir {} {
	variable config

	.root.pnd.left.top delete [ .root.pnd.left.top children {} ]
	set magento_dir [ tk_chooseDirectory -initialdir ~ -title "Choose Magnto root..." ]
	if { $magento_dir eq "" } {
	    .root.status.lab configure -text [ mc "No Magento root selected..." ]
	    return false
	} else {
	    dict set config magento_dir $magento_dir
	    save_config
	    .root.status.lab configure -text [ mc "Magento root set to " ]$magento_dir
	    ::system::windows::add_progress
	    ::system::utils::fill_directory_tree
	    ::system::windows::remove_progress
	}
    }

    proc get_highlight_groups {} {
	global highlight_groups
	if {[catch { source $::load_path/etc/ext/types.cfg } error]} {
	    puts $error
	    set highlight_groups 0 
	}
    }

    proc load_ext_file { entry } {
	global editor
	global highlight_groups
	set name_space [string trim [file extension [file normalize $editor($entry,file_name)]] . ]
	set ext_name $::load_path/etc/ext/$name_space.ext
	if {[file exists $ext_name]} {
	    source $ext_name
	    foreach group [array names highlight_groups] {
		set editor($entry.$group) $keywords($group)
	    }
	    set editor($entry.colorized) 1
	} else {
	    set editor($entry.colorized) 0
	}
    }
}

