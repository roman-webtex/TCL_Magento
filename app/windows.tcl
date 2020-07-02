# window utilites
#

namespace eval system::windows {

    variable cmd_console ""
    variable editor
    variable editor_no 0

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
	.root.pnd.left add .root.pnd.left.top
	.root.pnd.left add .root.pnd.left.bottom

	ttk::frame .root.status
	ttk::label .root.status.lab -text " " -anchor w
	ttk::sizegrip .root.status.size
	ttk::label .root.status.position -text " " -anchor w -padding "1"
	pack .root.status.size -side right -padx 2
	pack .root.status.lab -fill both -padx 2 -expand yes -side left
	pack .root.status.position -fill both -padx 2 -expand yes -side left 
	pack .root.status -side bottom -pady 2  -fill x

	menu .mainMenu.file -tearoff 0
	menu .mainMenu.edit -tearoff 0
	menu .mainMenu.magento -tearoff 0

	# main menu file
	menu .mainMenu.file.create -tearoff 0
	.mainMenu.file.create add command -label [ mc "Magento module" ] -command system::windows::module_window
	
        menu .mainMenu.file.open -tearoff 0
	.mainMenu.file.open add command -label [ mc "Magento module" ] -command system::magento::module_open

	.mainMenu.file add cascade -label [ mc "Create..." ] -underline 0 -menu .mainMenu.file.create
	.mainMenu.file add cascade -label [ mc "Open..." ] -underline 0 -menu .mainMenu.file.open
	.mainMenu.file add separator
	.mainMenu.file add command -label [ mc "Save" ] -command {::system::utils::save_file}
	.mainMenu.file add command -label [ mc "Save as..." ] -command {::system::utils::save_as_file}
	.mainMenu.file add separator
	.mainMenu.file add command -label [ mc "Close" ] -command {::system::utils::close_window} -accelerator "Ctrl-W"
	.mainMenu.file add separator
	.mainMenu.file add command -label [ mc "Exit" ] -command {::system::utils::my_exit} -accelerator "Ctrl-Q"

	# main menu edit
	.mainMenu.edit add command -label [ mc "Show editor" ] -command {::system::windows::show_editor}
	.mainMenu.edit add checkbutton -label [ mc "Show line number" ] -variable editor(show_line_number) -command {::system::windows::check_show_line}
	.mainMenu.edit add separator
	.mainMenu.edit add checkbutton -label [ mc "Editor history" ] -variable editor(show_history) -command {::system::windows::history_window}

	# main menu magento
	menu .mainMenu.magento.admin -tearoff 0
	.mainMenu.magento.admin add command -label [ mc ":admin:user:create" ] -command system::magento::admin_create
	
	menu .mainMenu.magento.setup -tearoff 0
	.mainMenu.magento.setup add command -label [ mc ":install" ] -command system::magento::setup_install
	.mainMenu.magento.setup add command -label [ mc ":upgrade" ] -command system::magento::setup_upgrade
	.mainMenu.magento.setup add command -label [ mc ":di:compile" ] -command system::magento::setup_di_compile
	.mainMenu.magento.setup add command -label [ mc ":static-content:deploy" ] -command system::magento::setup_deploy
	
	.mainMenu.magento add cascade -label [ mc "Setup" ] -underline 0 -menu .mainMenu.magento.setup
	.mainMenu.magento add cascade -label [ mc "Admin" ] -underline 0 -menu .mainMenu.magento.admin
	.mainMenu.magento add separator
	.mainMenu.magento add command -label [ mc "MySql" ] -underline 0 -command {::system::sql::request::init "catalog_product" }
	.mainMenu.magento add separator
	.mainMenu.magento add command -label [ mc "Add Model" ] -underline 0 -command {::system::magento::add_model}
	.mainMenu.magento add separator
	.mainMenu.magento add command -label [ mc "Open Magento directory" ] -underline 0 -command  ::system::config::select_magento_dir
	
	.mainMenu add cascade -label [ mc "File" ] -underline 0 -menu .mainMenu.file
	.mainMenu add cascade -label [ mc "Editor" ] -underline 0 -menu .mainMenu.edit
	.mainMenu add cascade -label [ mc "Magento" ] -underline 0 -menu .mainMenu.magento

	restore_session

	bind . <Control-q> {::system::utils::my_exit}
	bind . <Control-w> {::system::utils::close_window}
	bind . <Control-s> {::system::utils::save_file}
	bind .root.pnd.notebook <<NotebookTabChanged>> {::system::utils::handle_tab_changed}
	bind .root.pnd.left.top <<TreeviewOpen>> {::system::utils::fill_directory_tree [%W focus]}
	bind .root.pnd.left.top <Double-1> {::system::utils::handle_treeview_select [%W focus]}
    }

    proc check_show_line {} {
        
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

    proc show_editor {} {
	global editor
	set $editor(console) 0
	set $editor(show_history) 0

	if {[winfo exists .history_paned] == 1 && [lsearch [.root.pnd panes] .history_paned] == 1} {
	    .root.pnd forget .history_paned
	}

	if {[winfo exists .console_paned] == 1 && [lsearch [.root.pnd panes] .console_paned] == 1} {
	    .root.pnd forget .console_paned
	}

	if {[lsearch [.root.pnd panes] .root.pnd.notebook] == -1} {
	    .root.pnd add .root.pnd.notebook
	}
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
	set session [::system::config::restore_session]
	foreach item [split $session " "]  {
	    ::system::windows::edit_file dep_ident [lindex [split $item :] 0] [lindex [split $item :] 1] 
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
	ttk::button .params_window.paned.right.buttonframe.button -text "Run" -command { set done 1 } -width 15
	pack .params_window.paned.right.buttonframe.button -padx 4 -pady 4
	centre_window .params_window

	vwait done

	destroy .params_window

	dict for { name value } $params {
	    eval "dict set result $name \${$name}"
	}
	return $result
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

    proc module_window_close {} {
	.mainMenu delete last
	destroy .mainMenu.module
    }

    proc edit_file {item_dep path {position 1.0}} {
	global editor
	global highlight_groups
	global format_position
	global editor_no

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

	if {[winfo exists .history_paned] == 1} {
	    .root.pnd forget .history_paned
	    .root.pnd add .root.pnd.notebook
	    set $editor(show_history) 0
	}
	
	remove_progress
    }

    proc history_window {} {
	global load_path
	global editor

	if {$editor(show_history) == 1} {
	    .root.pnd forget .root.pnd.notebook

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
	} else {

	    if {[winfo exists .history_paned] == 1} {
		.root.pnd forget .history_paned
	    }
	    .root.pnd add .root.pnd.notebook
	}
	bind .history_tree <Double-1> {::system::utils::handle_history_treeview_select [%W focus]}
    }

    proc get_types_select {{ parent .}} {
	set retval [ttk::combobox .combo]
    }

    proc get_model_window { {model_name ""} } {
	global fields_no
	set fields_no 0
	
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
	pack .model_window.paned.right.model_name -side top -anchor w -padx 4 -pady 4
	ttk::label .model_window.paned.left.model_name.label -text "Model name :" -padding "1 1 1 1"
	ttk::entry .model_window.paned.right.model_name.value -textvariable model_name

	# model table
	frame .model_window.paned.right.model_table
	frame .model_window.paned.left.model_table
	pack .model_window.paned.left.model_table -side top -anchor w -padx 4 -pady 4
	pack .model_window.paned.right.model_table -side top -anchor w -padx 4 -pady 4
	ttk::label .model_window.paned.left.model_table.label -text "Model Table name :" -padding "1 1 1 1"
	ttk::entry .model_window.paned.right.model_table.value -textvariable model_table_name
	ttk::label .model_window.paned.left.label -text "Fields :" -padding "1 1 1 1"
	pack .model_window.paned.left.model_name.label
	pack .model_window.paned.right.model_name.value
	pack .model_window.paned.left.model_table.label
	pack .model_window.paned.right.model_table.value
	pack .model_window.paned.left.label

	set field_$fields_no ""
	frame .model_window.field_$fields_no
	pack .model_window.field_$fields_no -side top -anchor nw -padx 4 -pady 4
	ttk::entry .model_window.field_$fields_no.name -textvariable field_$fields_no
	pack .model_window.field_$fields_no.name -side top -anchor nw -padx 4 -pady 4


	frame .model_window.buttonframe
	pack .model_window.buttonframe -side top -anchor e -padx 4 -pady 4
	ttk::button .model_window.buttonframe.button -text "Run" -command { set done 1 } -width 15
	pack .model_window.buttonframe.button -padx 4 -pady 4

	centre_window .model_window

	vwait done

	destroy .model_window
	
    }
}
