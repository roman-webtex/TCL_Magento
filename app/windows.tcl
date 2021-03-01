# Tcl/Tk Magento Helper                
# Distrubuted under GPL               
# Copyright (c) "Roman Dmytrenko", 2020       
# Author: Roman Dmytrenko roman.webtex@gmail.com 
#
# window utilites
#
namespace eval system::windows {

    variable cmd_console ""
    variable editor
    variable editor_no 0
    variable window_radio

    set editor(show_line_number) 0
    
    proc centre_window { w } {
        after idle "
                update idletasks

                if {[winfo exists $w] == 1} {
                    # centre
                    set xmax \[winfo screenwidth $w\]
                    set ymax \[winfo screenheight $w\]
                    set x \[expr \{(\$xmax - \[winfo reqwidth $w\]) / 2\}\]
                    set y \[expr \{(\$ymax - \[winfo reqheight $w\]) / 2\}\]

                    wm geometry $w \"+\$x+\$y\"
                }
                "
    }
    
    proc main_window {} {
        global editor
	global window_radio
        global project

        set editor(console) 0
        
        wm title . "Magento Helper"
        . configure -menu [ menu .mainMenu ]

        # main frame
        ttk::frame .root 
        pack .root -fill both -expand 1 

        ttk::panedwindow .root.pnd -orient horizontal
        pack .root.pnd -fill both -expand 1 

        ttk::panedwindow .root.pnd.left -orient vertical -width 350
        .root.pnd add .root.pnd.left

        ttk::notebook .root.pnd.notebook -padding "1 0"
        ttk::scrollbar .root.scrollbary -orient vertical -takefocus 1
        pack .root.scrollbary -in .root.pnd.notebook -side right -fill y
        ttk::scrollbar .root.scrollbarx -orient horizontal -takefocus 1
        pack .root.scrollbarx -in .root.pnd.notebook -side bottom -fill x

        .root.pnd add .root.pnd.notebook
        ttk::notebook::enableTraversal .root.pnd.notebook
        
        ttk::treeview .root.pnd.left.top -padding "1 0 0 1" -height 35 -columns {path type} -displaycolumns {} -selectmode browse
        .root.pnd.left.top heading #0 -text [ mc "Magento root directory" ]

        ttk::treeview .root.pnd.left.bottom -padding "1 0 0 1" -columns {file_name line_no} -displaycolumns {} -selectmode browse
        .root.pnd.left add .root.pnd.left.top -weight 1
        .root.pnd.left add .root.pnd.left.bottom -weight 2

        ttk::frame .root.status
        ttk::label .root.status.lab -text " " -anchor w
        ttk::sizegrip .root.status.size
        ttk::label .root.status.position -text " " -anchor w -padding "1"
        pack .root.status.size -side right -padx 2
        pack .root.status.lab -fill both -padx 2 -expand yes -side left
        pack .root.status.position -fill both -padx 2 -expand yes -side left 
        pack .root.status -side bottom -pady 2  -fill x

        menu .mainMenu.file -tearoff 0
        menu .mainMenu.window -tearoff 0
        menu .mainMenu.magento -tearoff 0
        menu .mainMenu.plugins -tearoff 0

        # main menu file
        menu .mainMenu.file.create -tearoff 0
        .mainMenu.file.create add command -label [ mc "Magento module" ] -command ::system::windows::create_module_window
        
        menu .mainMenu.file.open -tearoff 0
        .mainMenu.file.open add command -label [ mc "File" ] -command {::system::windows::edit_file dep_ident [system::utils::open_file "Open..." [pwd] "*"]}
        .mainMenu.file.open add command -label [ mc "Project" ] -command system::windows::open_project_from_menu
        .mainMenu.file.open add command -label [ mc "Magento module" ] -command system::magento::open_module_from_menu

        .mainMenu.file add cascade -label [ mc "Create..." ] -underline 0 -menu .mainMenu.file.create
        .mainMenu.file add cascade -label [ mc "Open..." ] -underline 0 -menu .mainMenu.file.open
        .mainMenu.file add separator
        .mainMenu.file add command -label [ mc "Save" ] -command {::system::utils::save_file}
        .mainMenu.file add command -label [ mc "Save as..." ] -command {::system::utils::save_as_file}
        .mainMenu.file add separator
        .mainMenu.file add command -label [ mc "Close" ] -command {::system::utils::close_window} -accelerator "Ctrl-W"
        .mainMenu.file add separator
        .mainMenu.file add command -label [ mc "Exit" ] -command {::system::utils::my_exit} -accelerator "Ctrl-Q"

        # main menu window
        .mainMenu.window add radiobutton -label [ mc "Editor window" ] -command {::system::windows::show_editor_window}
        .mainMenu.window add radiobutton -label [ mc "Module window" ] -command {::system::windows::show_module_window}
        .mainMenu.window add radiobutton -label [ mc "Console window" ] -command {::system::windows::show_console_window}
        .mainMenu.window add radiobutton -label [ mc "History window" ] -command {::system::windows::show_history_window}

        # main menu magento
        menu .mainMenu.magento.admin -tearoff 0
        .mainMenu.magento.admin add command -label [ mc ":admin:user:create" ] -command system::magento::admin_create
        
        menu .mainMenu.magento.setup -tearoff 0
        .mainMenu.magento.setup add command -label [ mc ":install" ] -command system::magento::setup_install
        .mainMenu.magento.setup add command -label [ mc ":upgrade" ] -command system::magento::setup_upgrade
        .mainMenu.magento.setup add command -label [ mc ":di:compile" ] -command system::magento::setup_di_compile
        .mainMenu.magento.setup add command -label [ mc ":static-content:deploy" ] -command system::magento::setup_deploy

        menu .mainMenu.magento.modules -tearoff 0
        
        .mainMenu.magento add cascade -label [ mc "Setup" ] -underline 0 -menu .mainMenu.magento.setup
        .mainMenu.magento add cascade -label [ mc "Admin" ] -underline 0 -menu .mainMenu.magento.admin
        .mainMenu.magento add separator
        .mainMenu.magento add command -label [ mc "Add Model" ] -underline 0 -command {::system::magento::add_model}
        .mainMenu.magento add command -label [ mc "Add Admin GridView for Model" ] -underline 0 -command {::system::magento::add_admin_gridview_model}        
        .mainMenu.magento add separator
        .mainMenu.magento add command -label [ mc "Open Magento directory" ] -underline 0 -command  ::system::config::select_magento_dir
        .mainMenu.magento add separator
        .mainMenu.magento add cascade -label [ mc "Project Modules" ] -underline 0 -menu .mainMenu.magento.modules

        .mainMenu add cascade -label [ mc "File" ] -underline 0 -menu .mainMenu.file
        .mainMenu add cascade -label [ mc "Magento" ] -underline 0 -menu .mainMenu.magento
        .mainMenu add cascade -label [ mc "Plugins" ] -underline 0 -menu .mainMenu.magento.modules
        .mainMenu add cascade -label [ mc "Window" ] -underline 0 -menu .mainMenu.window

        restore_session

        bind . <Control-q> {::system::utils::my_exit}
        bind . <Control-w> {::system::utils::close_window}
        bind . <Control-s> {::system::utils::save_file}
        bind .root.pnd.notebook <<NotebookTabChanged>> {::system::utils::handle_tab_changed}
        bind .root.pnd.left.top <<TreeviewOpen>> {::system::utils::fill_directory_tree [%W focus]}
        bind .root.pnd.left.top <Double-1> {::system::utils::handle_treeview_select [%W focus]}
        bind .root.pnd.left.top <Return> {::system::utils::handle_treeview_select [%W focus]}
    }

    proc open_project_from_menu {} {
        set project_file_name [system::utils::open_file "Open Project" $::load_path/etc/projects/ "*.tmproj"]
        if {$project_file_name != ""} {
            ::system::config::load_project $project_file_name
        }
    }

    proc tooltip {text posx posy} {

        if {[winfo exists .tooltip] == 0} {
            toplevel .tooltip
            wm attribute .tooltip -type tooltip
            wm overrideredirect .tooltip 1
            wm transient .tooltip .
            ttk::label .tooltip.label -relief flat -borderwidth 1 -text $text -background "light gray"
            pack .tooltip.label -fill both -expand 1 -padx 10 -pady 2 
        }
        wm geometry .tooltip "+$posx+[expr $posy - 40]"
        wm deiconify .tooltip
    }

    proc get_popup {entry} {
        global editor

        if {[winfo exists .autocomplete] == 0} {
            toplevel .autocomplete
            wm attribute .autocomplete -type tooltip 
            wm overrideredirect .autocomplete 0
            wm transient .autocomplete .
            #ttk::entry .autocomplete.entry -background "light gray" 
            #pack .autocomplete.entry -fill y -expand 1 -padx 1 -pady 2 -anchor n
            listbox .autocomplete.body -relief flat -borderwidth 1 -background "light gray" -width 0
            pack .autocomplete.body -anchor s
        }
        wm geometry .autocomplete "+400+100"
        wm deiconify .autocomplete
    }

    proc popup_add { entry } {
        if {[set count [llength $entry]] > 25 } {
            .autocomplete.body configure -height 25
        } else {
            .autocomplete.body configure -height $count
        }
        
        foreach item $entry {
            .autocomplete.body insert end $item
        }
        .autocomplete.body selection set 0
        wm focusmodel .autocomplete active
    }

    proc show_module_window { {file_name ""} } {
	add_progress
	
	close_windows

	if {[winfo exists .module_note] == 0} {
	    ttk::notebook .module_note -padding "1 0"
	}

	.root.pnd add .module_note
	ttk::notebook::enableTraversal .module_note

	remove_progress
    }

    proc show_editor_window {} {
        global editor
	global window_radio
        set $editor(console) 0

	close_windows

        if {[lsearch [.root.pnd panes] .root.pnd.notebook] == -1} {
            .root.pnd add .root.pnd.notebook
        }
	set window_radio 1
    }

    proc open_magento {} {
        if { [ ::system::config::get_magento_dir ] eq "" } {
            ::system::config::select_magento_dir
        } else {
            .root.pnd.left.top delete [ .root.pnd.left.top children {} ]

            add_progress
            ::system::utils::fill_directory_tree
            remove_progress
            .root.status.lab configure -text [ mc "Magento root set to " ][ ::system::config::get_magento_dir ]
        }
    }

    proc restore_session {} {
        global project
        set session [::system::config::restore_session]
        foreach item [split $session " "]  {
            if {[lindex [split $item :] 0] != "current_project"} {
                ::system::windows::edit_file dep_ident [lindex [split $item :] 0] [lindex [split $item :] 1]
            } else {
                ::system::config::load_project [lindex [split $item :] 1]
            }
        }
    }

    proc add_progress { { maximum 20 } } {
        if {[winfo exists .pw] == 0} {
            set progress_count 0
            toplevel .pw
            wm title .pw "Wait..."
            wm attribute .pw -type tooltip
            wm overrideredirect .pw 0
            wm transient .pw .
            ttk::frame .pw.pf -relief sunken -borderwidth 1
            pack .pw.pf -fill both -expand 1 -padx 1 -pady 1 
            ttk::progressbar .pw.pf.pb -maximum $maximum -mode indeterminate
            pack .pw.pf.pb -fill x -expand 1 -padx 2 -pady 2
            .pw.pf.pb start
            set xmax [winfo screenwidth .pw]
            set ymax [winfo screenheight .pw]
            set x [expr {($xmax - [winfo reqwidth .pw]) / 2}]
            set y [expr {($ymax - [winfo reqheight .pw]) / 2}]
            wm geometry .pw "+$x+$y"
            wm deiconify .pw
        }
    }

    proc remove_progress {} {
        if {[winfo exists .pw] == 1} {
            destroy .pw
        }
    }

    proc get_console {} {
        global editor
	global window_radio
        variable cmd_console
        
        if {$editor(console) == 0} {

            if {[lsearch [.root.pnd panes] .root.pnd.notebook] == 1} {
                .root.pnd forget .root.pnd.notebook
            }

            if {[winfo exists .console_paned] == 0} {
                ttk::panedwindow .console_paned -orient horizontal
                ttk::notebook .console_paned.notebook -padding "1 0"
                .console_paned add .console_paned.notebook

                set cmd_console [ text .console_viewer -relief sunken -state normal -bd 1 -bg black -fg "light gray" -yscrollcommand [ list .root.scrollbary set ] ]
                .root.scrollbary configure -command [list $cmd_console yview]
                .console_paned.notebook add $cmd_console -text [ mc "console "][ ::system::config::get_magento_dir ]
            }
            .console_viewer delete 0.0 end
            if {[lsearch [.root.pnd panes] .console_paned] == -1} {
                .root.pnd add .console_paned
            }
        } else {

            if {[winfo exists .console_paned] == 1} {
                .root.pnd forget .console_paned
            }
            .root.pnd add .root.pnd.notebook
        }
	set window_radio 3
    }

    proc get_params_window { params } {
        toplevel .params_window
        wm title .params_window "Enter values"
        wm transient .params_window .
        ttk::panedwindow .params_window.paned -orient horizontal
        pack .params_window.paned -fill both -expand 1
        ttk::frame .params_window.paned.left 
        ttk::frame .params_window.paned.right 
        .params_window.paned add .params_window.paned.left
        .params_window.paned add .params_window.paned.right
        dict for { name value } $params {
            eval "global ${name}"
            eval "set ${name} $value"
            frame .params_window.paned.left.$name
            pack .params_window.paned.left.$name -side top -anchor w -padx 4 -pady 4
            frame .params_window.paned.right.$name 
            pack .params_window.paned.right.$name -side top -anchor w -padx 4 -pady 4 

            if { $value == 0 || $value == 1 } {
                eval "ttk::checkbutton .params_window.paned.right.$name.value -variable {${name}} -text \"${name}\""
            } else {
                ttk::label .params_window.paned.left.$name.label -text "${name} :" -padding "1 1 1 1"
                eval "ttk::entry .params_window.paned.right.$name.value -textvariable {${name}}"
                pack .params_window.paned.left.$name.label -side left
            }
            pack .params_window.paned.right.$name.value -side right
        }
        frame .params_window.paned.right.buttonframe
        pack .params_window.paned.right.buttonframe -side top -anchor e -padx 4 -pady 4
        ttk::button .params_window.paned.right.buttonframe.button -text "Ok" -command { set done 1 } -width 15
        pack .params_window.paned.right.buttonframe.button -padx 4 -pady 4
        centre_window .params_window

        vwait done

        destroy .params_window

        dict for { name value } $params {
            eval "dict set result $name \${$name}"
        }
        return $result
    }

    proc close_windows {} {
        if {[winfo exists .history_paned] == 1 && [lsearch [.root.pnd panes] .history_paned] == 1} {
            .root.pnd forget .history_paned
        }

        if {[winfo exists .console_paned] == 1 && [lsearch [.root.pnd panes] .console_paned] == 1} {
            .root.pnd forget .console_paned
        }

        if {[winfo exists .module_note] == 1 && [lsearch [.root.pnd panes] .module_note] == 1} {
            .root.pnd forget .module_note
        }

        if {[winfo exists .root.pnd.notebook] == 1 && [lsearch [.root.pnd panes] .root.pnd.notebook] == 1} {
            .root.pnd forget .root.pnd.notebook
        }
    }

    proc module_window {{ module "" }} {
        if {[ winfo exists .root.pnd.notebook.console ]} {
            destroy .root.pnd.notebook.console
            .root.scrollbar configure -command {}
            set cmd_console ""
        }
        menu .mainMenu.module -tearoff 0
        .mainMenu.module add command -label [ mc "General Infoimation" ]
        .mainMenu.module add separator
        .mainMenu.module add command -label [ mc "Data models" ]
        .mainMenu.module add command -label [ mc "Observers" ]
        .mainMenu.module add command -label [ mc "Plugins" ]
        .mainMenu.module add command -label [ mc "Blocks" ]
        .mainMenu.module add command -label [ mc "Layouts" ]
        .mainMenu.module add command -label [ mc "UI components" ]
        .mainMenu.module add separator
        .mainMenu.module add command -label [ mc "Close without save" ] -command ::system::windows::module_window_close
        .mainMenu.module add command -label [ mc "Save module" ]

        .mainMenu add cascade -label [ mc "Module" ] -underline 0  -menu .mainMenu.module
    }

    proc edit_file {item_dep path {position 1.0}} {
        global editor
        global highlight_groups
        global format_position
        global editor_no

        if {[file exists $path] == 0} {
            return
        }

        add_progress
        update

        set item 0

        foreach element [lsort -dictionary [array names editor *,file_path]] {
            if {$editor($element) == $path} {
                set item $element
            }
        }

        if {[ winfo exists $item ]} {
            .root.pnd.notebook select $item
            ::system::utils::get_functions $item
        } else {
            incr editor_no
            set item $editor_no
	    
            set file_editor [ text .root.pnd.notebook.$item -relief sunken -bd 1 -bg black -fg "light gray" \
                                  -yscrollcommand [ list .root.scrollbary set ] -xscrollcommand [ list .root.scrollbarx set] \
                                  -state normal -wrap none -blockcursor 1 -insertbackground {dark green} ]

            .root.scrollbary configure -command [list $file_editor yview]
            .root.scrollbarx configure -command [list $file_editor xview]

	    .root.pnd.notebook add $file_editor -text [ file tail $path ]
	    
	    # for lineno
	    #trace add execution $file_editor leave [list ::system::utils::handle_line_no $file_editor ]
	    #bind $file_editor <Configure> [list ::system::utils::handle_line_no $file_editor ]

            update
            
            set file_data [::system::utils::get_file_content $path]
            update
            
            ::system::parser::parse_php $path
            set editor($file_editor,file_path) $path
            set editor($file_editor,file_name) [ file tail $path ]
            set editor($file_editor,status) 0
            set editor($file_editor,functions) ""
            set editor($file_editor,variables) ""
            set editor($file_editor.addcontrols) 0
            set editor($file_editor.lastkey) ""
            set format_position 0

            $file_editor delete 0.0 end
            $file_editor insert 0.0 $file_data

            .root.pnd.notebook select $file_editor

                  
            foreach group [array names highlight_groups] {
                $file_editor tag configure $group -foreground $highlight_groups($group)
            }
            update
            
            ::system::config::load_ext_file $file_editor
            update
            
            ::system::utils::highlight_text $file_editor
            #::system::utils::highlight_all $file_editor
            
            $file_editor edit modified 0
            ::system::utils::handle_editor_update $file_editor
            update

            .root.pnd.left.bottom delete [.root.pnd.left.bottom children {}]

            if {[file extension $path] == ".php"} {
                update
                ::system::utils::get_class_structure $file_editor
            }

            event add <<FormatRegion>> <Control-i>

            bind $file_editor <<Modified>> {::system::utils::handle_editor_modify %W }
            bind $file_editor <<NotebookTabChanged>> {::system::utils::tab_change %W}
            bind $file_editor <KeyRelease> {::system::utils::handle_editor_update %W %K}
            bind $file_editor <ButtonRelease> {::system::utils::handle_editor_update %W %X %Y}
            bind $file_editor <<FormatRegion>> {::system::utils::handle_format_region %W}
            #bind $file_editor <Control-Button-1> {::system::utils::handle_editor_gotofile %W %X %Y}
 
            #bind $file_editor <KeyPress> {::system::utils::handle_editor_keypress %W %K}

            $file_editor mark set insert $position
            $file_editor see $position
            focus -force $file_editor

        }

	close_windows

	.root.pnd add .root.pnd.notebook

        set window_radio 1
        remove_progress
    }

    proc show_history_window {} {
        global load_path
        global editor
	global window_radio

	#.root.pnd forget .root.pnd.notebook
	close_windows

	if {[winfo exists .history_paned] == 0} {
	    ttk::panedwindow .history_paned -orient horizontal
	    ttk::treeview .history_tree -padding "1 0 0 1" -columns {edit_time real_path saved_path} -displaycolumns {edit_time real_path} -selectmode browse

	    .history_tree heading #0 -text [ mc "Filename" ] 
	    .history_tree heading #1 -text [ mc "Time" ] 
	    .history_tree heading #2 -text [ mc "Path" ]
	    
	    .history_tree column #0 -width 200 -stretch false
	    .history_tree column #1 -width 50 -stretch false
	    .history_tree column #2 -width 500 -stretch true

	    .history_paned add .history_tree

	    set history_viewer [ text .history_viewer -relief sunken -bd 1 -bg black -fg "light gray" \
				     -yscrollcommand [ list .root.scrollbary set ] -xscrollcommand [ list .root.scrollbarx set] \
				     -state normal -wrap none -blockcursor 1 -insertbackground {dark green} ]

	    .root.scrollbary configure -command [list $history_viewer yview]
	    .root.scrollbarx configure -command [list $history_viewer xview]

	    .history_paned add $history_viewer
	}
	.root.pnd add .history_paned
	::system::utils::fill_history 

        bind .history_tree <Double-1> {::system::utils::handle_history_treeview_select [%W focus]}
    }

    proc get_types_select {{ parent .}} {
        set retval [ttk::combobox .combo]
    }

    proc create_module_window {} {
        global module_name
        global module_version
        global module_depends
        global depends_no
        
        set module_name "Vendor_ModuleName"
        set module_version "0.0.1"
        set depends_no 0
        array unset module_depends
        
        toplevel .module_window
        wm title .module_window [mc "Create Module"]
        wm transient .module_window .
        ttk::panedwindow .module_window.paned -orient horizontal
        pack .module_window.paned -fill both -expand 1
        ttk::frame .module_window.paned.left
        ttk::frame .module_window.paned.right
        .module_window.paned add .module_window.paned.left
        .module_window.paned add .module_window.paned.right

        # module name
        frame .module_window.paned.left.module_name
        frame .module_window.paned.right.module_name
        pack .module_window.paned.left.module_name -side top -anchor w -padx 4 -pady 4
        pack .module_window.paned.right.module_name -side top -anchor w -padx 4 -pady 4
        ttk::label .module_window.paned.left.module_name.label -text [mc "Module name :"] -padding "1 1 1 1"
        ttk::entry .module_window.paned.right.module_name.value -textvariable module_name -width 45
        pack .module_window.paned.left.module_name.label
        pack .module_window.paned.right.module_name.value


        #module version
        frame .module_window.paned.left.module_version
        frame .module_window.paned.right.module_version
        pack .module_window.paned.left.module_version -side top -anchor w -padx 4 -pady 4
        pack .module_window.paned.right.module_version -side top -anchor w -padx 4 -pady 4
        ttk::label .module_window.paned.left.module_version.label -text [mc "Module version :"] -padding "1 1 1 1"
        ttk::entry .module_window.paned.right.module_version.value -textvariable module_version -width 45
        pack .module_window.paned.left.module_version.label
        pack .module_window.paned.right.module_version.value

        set module_depends($depends_no.depends_name) ""

        #module depends
        frame .module_window.paned.left.module_depends_$depends_no
        frame .module_window.paned.right.module_depends_$depends_no
        pack .module_window.paned.left.module_depends_$depends_no -side top -anchor w -padx 4 -pady 4
        pack .module_window.paned.right.module_depends_$depends_no -side top -anchor w -padx 4 -pady 4
        ttk::label .module_window.paned.left.module_depends_$depends_no.label -text [mc "Depends :"] -padding "1 1 1 1"
        ttk::entry .module_window.paned.right.module_depends_$depends_no.value -textvariable module_depends($depends_no.depends_name) -width 45
        pack .module_window.paned.left.module_depends_$depends_no.label
        pack .module_window.paned.right.module_depends_$depends_no.value
        
        frame .module_window.buttonframe
        pack .module_window.buttonframe -side top -anchor e -padx 4 -pady 4

        ttk::button .module_window.buttonframe.button_add -text [mc "Add Depends"] -command { ::system::windows::add_module_depends } -width 15
        pack .module_window.buttonframe.button_add -padx 4 -pady 4

        ttk::button .module_window.buttonframe.button_create -text [mc "Create Module"] -command { set module_done 1 } -width 15
        pack .module_window.buttonframe.button_create -padx 4 -pady 4

        ttk::button .module_window.buttonframe.button_cancel -text [mc "Cancel"] -command { destroy .module_window } -width 15
        pack .module_window.buttonframe.button_cancel -padx 4 -pady 4
        
        centre_window .module_window

        vwait module_done
        destroy .module_window

        set module_dir [::system::config::get_magento_dir]/app/code/[regsub -- _ $module_name /]
        
        if {[file exists $module_dir/etc/module.xml] != 0} {
            set reply [tk_dialog .foo "Magento Module" "The Module named '[regsub -- _ $module_name /]' are exist. Open it?" questhead 0 Yes No Cancel]
            switch -- $reply {
                0 {
                    ::system::magento::open_module $module_name
                }
                2 {
                    return
                }
            }
        }
        
        ::system::magento::create_module $module_name $module_version

        tk_messageBox -title "Ready" -message "The Module '$m_name' was successfully created." -type ok
    }

    proc add_module_depends {} {
        global depends_no
        global module_depends
        
        incr depends_no
        set module_depends($depends_no.depends_name) ""

        frame .module_window.paned.left.module_depends_$depends_no
        frame .module_window.paned.right.module_depends_$depends_no
        pack .module_window.paned.left.module_depends_$depends_no -side top -anchor w -padx 4 -pady 4
        pack .module_window.paned.right.module_depends_$depends_no -side top -anchor w -padx 4 -pady 4
        ttk::label .module_window.paned.left.module_depends_$depends_no.label -text [mc "Depends :"] -padding "1 1 1 1"
        ttk::entry .module_window.paned.right.module_depends_$depends_no.value -textvariable module_depends($depends_no.depends_name) -width 45
        pack .module_window.paned.left.module_depends_$depends_no.label -side top 
        pack .module_window.paned.right.module_depends_$depends_no.value -side top 
    }

    
    proc get_model_window { {model_name ""} } {
        global field_no
        global fields_list
        global field_types
        global create_model_name
        global create_model_table_name
        global project
        
        set field_no 0
        array unset fields_list

        if {$project(active) != ""} {
            set create_model_name "${project(active)}_Model_ModelName"
            set create_model_table_name [string tolower "${project(active)}_modelname"]
        } else {
            set create_model_name "Vendor_ModuleName_Model_ModelName"
            set create_model_table_name "vendor_module_modelname"
        }

        if {[llength $::system::magento::di_fields_type] == 0} {
            set ::system::magento::di_fields_type [::system::magento::get_db_field_types]
        }
        
        toplevel .model_window
        wm title .model_window "Enter values"
        wm transient .model_window .
        ttk::panedwindow .model_window.paned -orient horizontal
        pack .model_window.paned -fill both -expand 1
        ttk::frame .model_window.paned.left 
        ttk::frame .model_window.paned.right 
        .model_window.paned add .model_window.paned.left
        .model_window.paned add .model_window.paned.right

        # model name
        frame .model_window.paned.left.model_name
        frame .model_window.paned.right.model_name
        pack .model_window.paned.left.model_name -side top -anchor w -padx 4 -pady 4
        pack .model_window.paned.right.model_name -side top -anchor w -padx 4 -pady 4 -expand 1 -fill x
        ttk::label .model_window.paned.left.model_name.label -text "Model name :" -padding "1 1 1 1"
        ttk::entry .model_window.paned.right.model_name.value -textvariable create_model_name -width 45
        pack .model_window.paned.left.model_name.label
        pack .model_window.paned.right.model_name.value

        # model table
        frame .model_window.paned.right.model_table
        frame .model_window.paned.left.model_table
        pack .model_window.paned.left.model_table -side top -anchor w -padx 4 -pady 4
        pack .model_window.paned.right.model_table -side top -anchor w -padx 4 -pady 4 -expand 1 -fill x
        ttk::label .model_window.paned.left.model_table.label -text "Model Table name :" -padding "1 1 1 1"
        ttk::entry .model_window.paned.right.model_table.value -textvariable create_model_table_name -width 45
        pack .model_window.paned.left.model_table.label
        pack .model_window.paned.right.model_table.value

        set fields_list($field_no.name) "entity_id"
        set fields_list($field_no.type) "int"
        set fields_list($field_no.size) 10
        set fields_list($field_no.null) 1
        set fields_list($field_no.default) ""
        set fields_list($field_no.attribute) ""
        set fields_list($field_no.index) "PRIMARY"
        set fields_list($field_no.ai) 1

        frame .model_window.field
        pack .model_window.field -side top -anchor nw -padx 4 -pady 4
        ttk::label .model_window.field.name -text "Field Name" -width 30
        ttk::label .model_window.field.type -text "Type" -width 9 
        ttk::label .model_window.field.size -text "Size" -width 5
        ttk::label .model_window.field.null -text "not Null" -width 8
        ttk::label .model_window.field.default -text "Default" -width 20
        ttk::label .model_window.field.attribute -text "Attribute" -width 10
        ttk::label .model_window.field.index -text "Index" -width 10
        ttk::label .model_window.field.ai -text "AI" -width 5
        
        grid .model_window.field.name -row 0 -column 0 -padx 5 -pady 1
        grid .model_window.field.type -row 0 -column 1 -padx 5 -pady 1
        grid .model_window.field.size -row 0 -column 2 -padx 5 -pady 1
        grid .model_window.field.null -row 0 -column 3 -padx 1 -pady 1
        grid .model_window.field.default -row 0 -column 4 -padx 10 -pady 1
        grid .model_window.field.attribute -row 0 -column 5 -padx 10 -pady 1
        grid .model_window.field.index -row 0 -column 6 -padx 1 -pady 1
        grid .model_window.field.ai -row 0 -column 7 -padx 1 -pady 1
        
        frame .model_window.field_$field_no
        pack .model_window.field_$field_no -side top -anchor nw -padx 4 -pady 4
        ttk::entry .model_window.field_$field_no.name -textvariable fields_list($field_no.name) -width 30
        ttk::combobox .model_window.field_$field_no.type -textvariable fields_list($field_no.type) -width 9 -values $::system::magento::di_fields_type
        ttk::entry .model_window.field_$field_no.size -textvariable fields_list($field_no.size) -width 5
        ttk::checkbutton .model_window.field_$field_no.null -variable fields_list($field_no.null) -width 5
        ttk::entry .model_window.field_$field_no.default -textvariable fields_list($field_no.default) -width 20
        ttk::combobox .model_window.field_$field_no.attribute -textvariable fields_list($field_no.attribute) -width 9 -values [::system::magento::get_fields_attribute]
        ttk::combobox .model_window.field_$field_no.index -textvariable fields_list($field_no.index) -width 9 -values [::system::magento::get_fields_index]
        ttk::checkbutton .model_window.field_$field_no.ai -variable fields_list($field_no.ai) -width 5  
        
        grid .model_window.field_$field_no.name -row $field_no -column 0 -padx 1 -pady 1
        grid .model_window.field_$field_no.type -row $field_no -column 1 -padx 1 -pady 1
        grid .model_window.field_$field_no.size -row $field_no -column 2 -padx 1 -pady 1
        grid .model_window.field_$field_no.null -row $field_no -column 3 -padx 15 -pady 1
        grid .model_window.field_$field_no.default -row $field_no -column 4 -padx 1 -pady 1
        grid .model_window.field_$field_no.attribute -row $field_no -column 5 -padx 1 -pady 1
        grid .model_window.field_$field_no.index -row $field_no -column 6 -padx 1 -pady 1
        grid .model_window.field_$field_no.ai -row $field_no -column 7 -padx 15 -pady 1
        
        frame .model_window.buttonframe
        pack .model_window.buttonframe -side top -anchor e -padx 4 -pady 4

        ttk::button .model_window.buttonframe.button_add -text "Add Field" -command { ::system::windows::add_model_field } -width 15
        pack .model_window.buttonframe.button_add -padx 4 -pady 4

        ttk::button .model_window.buttonframe.button_create -text "Create Model" -command { set model_done 1 } -width 15
        pack .model_window.buttonframe.button_create -padx 4 -pady 4

        ttk::button .model_window.buttonframe.button_cancel -text "Cancel" -command { destroy .model_window } -width 15
        pack .model_window.buttonframe.button_cancel -padx 4 -pady 4
        
        bind .model_window.field_$field_no.index <<ComboboxSelected>> {::system::magento::get_index_name $field_no}

        centre_window .model_window

        vwait model_done
        destroy .model_window

        set module_dir [::system::config::get_magento_dir]/app/code/[regsub -- _ [regsub -- {_Model.*$} $create_model_name ""] /]
        
        if {[file exists $module_dir/etc/module.xml] == 0} {
            set reply [tk_dialog .foo "Magento Module" "The Module named '[regsub -- {_Model.*$} $create_model_name ""]' does not exist. Create from template?" questhead 0 Yes No Cancel]
            switch -- $reply {
                0 {
                    ::system::magento::create_module $create_model_name
                }
                2 {
                    return
                }
            }
        }
        ::system::magento::create_model $create_model_name $create_model_table_name
    }

    proc add_model_field {} {
        global field_no
        global fields_list
        
        incr field_no
        set fields_list($field_no.name) ""
        set fields_list($field_no.type) ""
        set fields_list($field_no.size) ""
        set fields_list($field_no.null) 0
        set fields_list($field_no.default) ""
        set fields_list($field_no.attribute) ""
        set fields_list($field_no.index) ""
        set fields_list($field_no.ai) 0

        frame .model_window.field_$field_no
        pack .model_window.field_$field_no -side top -before .model_window.buttonframe -padx 4 -pady 4

        ttk::entry .model_window.field_$field_no.name -textvariable fields_list($field_no.name) -width 30
        ttk::combobox .model_window.field_$field_no.type -textvariable fields_list($field_no.type) -width 9 -values $::system::magento::di_fields_type
        ttk::entry .model_window.field_$field_no.size -textvariable fields_list($field_no.size) -width 5
        ttk::checkbutton .model_window.field_$field_no.null -variable fields_list($field_no.null) -width 5
        ttk::entry .model_window.field_$field_no.default -textvariable fields_list($field_no.default) -width 20
        ttk::combobox .model_window.field_$field_no.attribute -textvariable fields_list($field_no.attribute) -width 9 -values [::system::magento::get_fields_attribute]
        ttk::combobox .model_window.field_$field_no.index -textvariable fields_list($field_no.index) -width 9 -values [::system::magento::get_fields_index]
        ttk::checkbutton .model_window.field_$field_no.ai -variable fields_list($field_no.ai) -width 5  
        
        grid .model_window.field_$field_no.name -row $field_no -column 0 -padx 1 -pady 1
        grid .model_window.field_$field_no.type -row $field_no -column 1 -padx 1 -pady 1
        grid .model_window.field_$field_no.size -row $field_no -column 2 -padx 1 -pady 1
        grid .model_window.field_$field_no.null -row $field_no -column 3 -padx 15 -pady 1
        grid .model_window.field_$field_no.default -row $field_no -column 4 -padx 1 -pady 1
        grid .model_window.field_$field_no.attribute -row $field_no -column 5 -padx 1 -pady 1
        grid .model_window.field_$field_no.index -row $field_no -column 6 -padx 1 -pady 1
        grid .model_window.field_$field_no.ai -row $field_no -column 7 -padx 15 -pady 1

        bind .model_window.field_$field_no.index <<ComboboxSelected>> {::system::magento::get_index_name $field_no}
    }

    proc admin_gridview_model_window {} {
        global project

        set module_list ""
        
        foreach module_index [array names project module.*] {
            lappend module_list $project($module_index)    
        }

        if {$module_list == ""} {
            tk_messageBox -title "No module" -message "Please, select working module from menu File -> Open... -> Magento module" -type ok
            return
        }

        foreach module [list $module_list] {
            set models_dir [::system::config::get_magento_dir]/app/code/[regsub -- _ $module /]/Api/Data/
            foreach model_path [glob -nocomplain $models_dir*Interface.php] {
                set project(module_interface.$module.[regsub -all -- "Interface.php" [file tail $model_path] ""]) $model_path
                set project(module_model.$module.[regsub -all -- "Interface.php" [file tail $model_path] ""]) [::system::config::get_magento_dir]/app/code/[regsub -- _ $module /]/Model/[regsub -all -- "Interface" [file tail $model_path] ""]
            }
        }

        toplevel .gridview_window
        wm title .gridview_window "Create Admin Gridview"
        wm transient .gridview_window .
        ttk::panedwindow .model_window.paned -orient horizontal
        pack .model_window.paned -fill both -expand 1
        ttk::frame .model_window.paned.left 
        ttk::frame .model_window.paned.right 
        .model_window.paned add .model_window.paned.left
        .model_window.paned add .model_window.paned.right
      
    }
}
