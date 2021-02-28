# Tcl/Tk Magento Helper                
# Distrubuted under GPL               
# Copyright (c) "Roman Dmytrenko", 2020       
# Author: Roman Dmytrenko roman.webtex@gmail.com 
#
#
# Magento Instance info
#

namespace eval ::system::magento::info {
    variable info_notebook

    proc init {} {
        variable info_notebook

        set info_notebook [::systen::windows::get_notebook_widget]
        set info_tab [::system::windows::add_notebook_tab $info_notebook]
        
        
    }
}
