#
# Tcl/Tk Magento Helper                
# Distrubuted under GPL               
# Copyright (c) "Roman Dmytrenko", 2020       
# Author: Roman Dmytrenko roman.webtex@gmail.com 
#
# system configuration
#
namespace eval system::config {

    global config config_db editor highlight_groups project

    proc load_config {{project_name "DEFAULT"}} {
        global project
        global config_db

        variable config

        if {[file exists $::load_path/etc/system.cfg] != 0} {
            set config_db [::system::utils::get_file_content $::load_path/etc/system.cfg]
        } else {
            dict set config_db $project_name {}
        }

        set select [dict get $config_db $project_name]

        if { $select != "" } {

            foreach { key value } $select {
                dict set config $key $value
            }

            if {($project_name != "DEFAULT") && [dict get $config magento_dir] == ""} {
                dict set config magento_dir $project(magento_path)
            }
            
            set ::system::magento::di_fields_type [::system::magento::get_db_field_types]
        } else {
            dict set config magento_dir ""
            dict set config session {}
            dict set config project_name ""
            set system::magento::di_fields_type {}
        }

        if {[file exists $::load_path/etc/projects] == 0} {
            exec mkdir $::load_path/etc/projects
            dict set config project_name ""
            set project(project_name) ""
            set project(active) ""
        } elseif {[dict get $config project_name] == ""} {
            set project(project_name) ""
            set project(active) ""
        }
    }

    proc save_config {} {
        global project
        global config_db
        variable config

        set project_name $project(project_name)

        if {$project_name == ""} {
            set project_name "DEFAULT"
        }
        
        dict set config_db $project_name $config
        set fp [open $::load_path/etc/system.cfg w]
        puts $fp $config_db
        close $fp
    }

    proc get_magento_dir {} {
        variable config
        return [ dict get $config magento_dir ]
    }

    proc save_session {session} {
        global project
        variable config

        dict set config session $session
        if {([dict get $config magento_dir] == "") && ([::system::config::get_magento_dir] != "")} {
            dict set config magento_dir [::system::config::get_magento_dir]
        }
        save_config
    }

    proc save_project {} {
        global project
        variable config

        set file_data ""

        foreach line [array names project] {
            if {$line != ""} {
                append file_data $line|$project($line)\n
            }
        }
        set project_file_name $::load_path/etc/projects/[dict get $config project_name]
        set fp [open $project_file_name w]
        puts $fp $file_data
        close $fp
    }

    proc load_project {project_name} {
        global project
        variable config

        array unset project

        set project_file_name $::load_path/etc/projects/[file tail $project_name]

        if {[file exists $project_file_name] != 0} {
            set file_data [::system::utils::get_file_content $project_file_name]
            foreach line [split $file_data \n] {
                set project([lindex [split $line "|"] 0]) [lindex [split $line "|"] 1]
            }
        }

        load_config $project(project_name)

        ::system::windows::add_progress
        ::system::utils::fill_directory_tree

        .mainMenu.magento delete last
        destroy .mainMenu.magento.modules
        
        menu .mainMenu.magento.modules -tearoff 0

        foreach module [array names project module.*] {
            set mod_name $project($module)
            .mainMenu.magento.modules add radiobutton -label $mod_name -variable $project(active) -command "::system::magento::set_active_module $mod_name"
        }
        .mainMenu.magento add cascade -label [ mc "Project Modules" ] -underline 0 -menu .mainMenu.magento.modules
        ::system::magento::set_active_module $project(active)

        ::system::windows::remove_progress
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

