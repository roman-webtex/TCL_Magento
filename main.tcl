#!/bin/env wish
#
# Tcl/Tk Magento Helper                
# Distrubuted under GPL               
# Copyright (c) "Roman Dmytrenko", 2020       
# Author: Roman Dmytrenko roman.webtex@gmail.com 
#

array set editor {}
array set parsed_data {}

set load_path [ file dirname [ file normalize [info script] ] ]

proc package_load { module err_message } {
    if { [ catch { package require $module } error ]} {
        puts $error
        puts $err_message
        exit
    }
}

if { $tcl_version < 8.6 || $tk_version < 8.6 } {
    puts "Required Tcl/Tk version 8.6"
    exit
}

package_load Tk { "Required Tk package." }
package_load msgcat { "Required msgcat package." }
package_load Img { "Required Img package." }
package_load sqlite3 { "Requires sqlite3 package" }
package_load mysqltcl { "Require mysqltcl package" }
package_load tdom { "Require tdom package" }

namespace import ::msgcat::mc

if { [ file exists $load_path/app/utils.tcl] == 0 } {
    puts "one or more core modules are not exists."
    exit
}

foreach { filename } [ glob -nocomplain $load_path/app/*.tcl] {
    source $filename
}


::system::config::load_config
::system::config::get_highlight_groups
::system::windows::main_window

foreach { filename } [ glob -nocomplain $load_path/modules/*.tcl] {
    update
    source $filename
    .mainMenu.magento.modules add command -label "[::system::[lindex [split [file tail $filename] . ] 0]::get_label]" -underline 0 -command {"::system::[lindex [split [file tail $filename] . ] 0]::run"}
}

::system::windows::open_magento


