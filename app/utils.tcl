# common utils
namespace eval system::utils {

    proc fill_directory_tree { { entry {} } } {
        if { $entry == {} } {
            set dir [ ::system::config::get_magento_dir ]
        } else {
            set dir [ .root.pnd.left.top set $entry path ]
            .root.pnd.left.top delete [.root.pnd.left.top children $entry]
        }

        set dir_list [ lsort -ascii [ glob -nocomplain -type d [ file join $dir * ] ] ] 
        foreach { current } [ split $dir_list " " ] {
            set child [ .root.pnd.left.top insert $entry end -text [ file tail $current ] -values [list $current [ file type $current]] ]
            .root.pnd.left.top insert $child end -text " "
        }

        set dir_content [ lsort -ascii [ glob -nocomplain -type f [ file join $dir * ] ] ]
        foreach { current_file } [ split $dir_content " " ] {
            .root.pnd.left.top insert $entry end -text [ file tail $current_file ] -values [list $current_file [file type $current_file]]
        }
    }

    proc handle_editor_modify { entry } {
        global editor
        if {[$entry edit modified] == 1} {
            .root.pnd.notebook tab $entry -text "$editor($entry,file_name) *"
            #tab_change $entry
        }
    }

    proc handle_tab_changed {} {
        global editor

        set file_editor [.root.pnd.notebook select]

        if {$file_editor != ".root.pnd.notebook.console"} {
            .root.pnd.left.bottom delete [.root.pnd.left.bottom children {}]
            ::system::utils::get_class_structure $file_editor
        }
    }

    proc handle_editor_gotofile { entry x y } {
        ::system::windows::tooltip "Test message ..." $x $y
    }

    proc handle_editor_update { entry {key ""} {x ""} {y ""} } {
        global editor
        global format_position
        global parsed_data

        if {[winfo exists .tooltip] == 1} {
            destroy .tooltip
        }

        set current_position [$entry index insert]
        set current_line [lindex [split $current_position .] 0]
        set line_position [lindex [split $current_position .] 1]
        set total_lines [expr [lindex [split [$entry index end] .] 0] - 1]
        .root.status.position configure -text "$line_position Line: $current_line of $total_lines"

        if {$key == "Control_L"} {

            
            set position [$entry index insert]
            set start [$entry search -backwards -- " " $position]
            set end  [$entry search " " $position]

            set var_name [string trim [$entry get $start $end] " \n{}(,"]
            set var_name [regsub -all -- {;.*$} $var_name "" ]
            set var_name [regsub -all -- {::.*$} $var_name "" ]

            # for function ...(\Vendor\Module_Name\... )
            if {[lindex [split $var_name "("] 1] != ""} {
                set var_name [lindex [split $var_name "("] 1]
            }

            set key "$editor($entry,file_path).$$var_name"
            set class  [lindex [array get parsed_data $key] 1]
            if {$class == ""} {
                set class_key "$editor($entry,file_path).used.$class"
                set class  [lindex [array get parsed_data $class_key] 1]
                if {$class != ""} {
                    set class [::system::magento::get_file_by_class_name $class]
                } else {
                    set class [::system::magento::get_file_by_class_name $var_name]
                }
            } else {
                set class [::system::magento::get_file_by_class_name $class]
            }

            if {[file exists $class] == 1} {
                ::system::windows::edit_file dep_ident $class 
            }
        }

        if {$key == "braceleft"} {
            $entry insert [$entry index insert] "\}"
            $entry mark set insert [$entry index insert-1chars]
        } elseif {$key == "parenleft"} {
            $entry insert [$entry index insert] "\)"
            $entry mark set insert [$entry index insert-1chars]
        } elseif {$key == "quotedbl"} {
            $entry insert [$entry index insert] "\""
            $entry mark set insert [$entry index insert-1chars]
        } elseif {$key == "apostrophe"} {
            $entry insert [$entry index insert] "'"
            $entry mark set insert [$entry index insert-1chars]
        } elseif {$key == "bracketleft"} {
            $entry insert [$entry index insert] "]"
            $entry mark set insert [$entry index insert-1chars]
        }

        if {$key == "greater"} {
            if {[$entry get "insert wordstart-2c" insert] == "->"} {
                get_var_element $entry minus ""
            }
        } elseif {$key == "colon"} {
            if {[$entry get "insert wordstart-2c" insert] == "::"} {
                get_var_element $entry colon ""
            }
        }

        if {$key == "Return"} {
            set pattern ""
            format_block $entry [$entry index "insert linestart"] end
        } elseif {$key == "braceright"} {
        }

        if {$editor($entry.addcontrols) == 1} {
            if {$key == "f"} {
                if {[string trim [$entry get [$entry index insert wordstart] [$entry index insert]]] == "if"} {
                    $entry insert [$entry index insert] " ( ) {\n\n}"
                    $entry mark set insert [$entry index "$current_position+3c"]
                }
            } elseif {$key == "h"} {
                if {[string trim [$entry get [$entry index insert wordstart] [$entry index insert]]] == "foreach"} {
                    $entry insert [$entry index insert] " ( ) {\n\n}"
                    $entry mark set insert [$entry index "$current_position+3c"]
                }
            } elseif {$key == "y"} {
                if {[string trim [$entry get [$entry index insert wordstart] [$entry index insert]]] == "try"} {
                    $entry insert [$entry index insert] " {\n} catch (\\Exception \$e) {\n}"
                    $entry mark set insert [$entry index "$current_position+3c"]
                }
            }
        }
        set editor($entry.lastkey) $key

	if {[lsearch -exact {space Tab minus colon parenleft parenright braceleft braceright quotedbl bracketleft bracketrighr slash backslash semicolon exclam at numbersign dollar percent asciicircum ampersand asterix equal plis bar less greater} $key] != -1} {
	    highlight_text $entry $current_line $current_line
	}
    }

    proc get_var_element {entry type pattern} {
        switch -- $type {
            minus {
                get_func_var_list $entry $pattern
            }
            colon {
                get_const_list $entry $pattern
            }
        }
    }

    proc handle_treeview_select { entry } {
        if {[.root.pnd.left.top set $entry type] eq "directory"} {
            return
        }
        ::system::windows::edit_file $entry [.root.pnd.left.top set $entry path]
    }

    proc remove_tags { entry begin end} {
        global highlight_groups

        foreach tag [array names highlight_groups] {
            $entry tag remove $tag $begin $end
        }
    }

    proc handle_editor_keypress { entry key } {
        set position_x [$entry index insert+1chars]
        set position_y [$entry index insert+2chars]
    }

    proc handle_line_no { entry args } {
	set benign {
	    mark bbox cget compare count debug dlineinfo
	    dump get index mark peer search
	}

	if {[llength $args] == 0 || [lindex $args 0 1] ni $benign} {
	    .root.pnd.canvas delete all
	    set i [$entry index @0,0]
	    set delta 25
	    while true {
		set dline [$entry dlineinfo $i]
		if {[llength $dline] == 0} break
		set height [lindex $dline 3]
		set y [lindex $dline 1]
		set cy [expr {$y + int($height/2.0)}]
		set linenum [lindex [split $i .] 0]
		.root.pnd.canvas create text 5 [expr $y + $delta] -anchor nw -text $linenum
		set i [$entry index "$i + 1 line"]
	    }
	}
    }

    proc handle_format_region { entry } {
        
    }

    proc highlight_text { entry {begin 1} {end "end"}} {
        global editor
        global highlight_groups
        
        if {$editor($entry.colorized) == 0} {
            return
        }
        
        set current_line $begin

        if {$end != "end"} {
            set end $end.end
        }

        remove_tags $entry [$entry index "insert wordstart"] [$entry index "insert wordend"]
        
        set end_line [lindex [ split [$entry index $end] .] 0]

        while {[set line [$entry get $current_line.0 [expr $current_line + 1].0 ]] != "" && $current_line <= $end_line } {
            update
            set work_line [string trim $line]
            if {[string range $work_line 0 0] == "#"} {
                $entry tag add comment $current_line.0 $current_line.end
            } else {
                set start_pos 0
                set length [string length $line]
                set word ""

                for {set x 0} {$x < $length} {incr x} {
                    set char [string range $line $x $x]

                    if {[set in_tag [is_in_tag comment $entry $current_line.$x]] != 0 } {

                        set tag_begin [lindex [split $in_tag " "] 0]
                        set tag_end [lindex [split $in_tag " "] 1]
                        set exp {\*/}
                        set delta_e 2

                        set tag_end [add_multiline_tag $entry comment $exp $tag_begin 0 $delta_e]
			set x [lindex [split $tag_end . ] 1]

			if {[lindex [split $tag_end .] 0] > $current_line} {
			    set current_line [expr [lindex [split $tag_end .] 0] - 1]
			    break
			}
                    }

                    if {$word == "//"} {
                        $entry tag add comment "$current_line.${x}-2c"  $current_line.end
                        set x $length
                        set word ""
                    } elseif {$word == "/*"} {
                        set tag_end [add_multiline_tag $entry comment {\*/} $current_line.$x 2 2]
			set x [lindex [split $tag_end .] 1];
			if {[lindex [split $tag_end .] 0] > $current_line} {
			    set current_line [expr [lindex [split $tag_end .] 0] -1 ]
			    break
			}
                    } elseif {$char == "\"" } {
                        set tag_end [add_multiline_tag $entry text {[^\\]\"} $current_line.$x 0 2]
			set x [lindex [split $tag_end . ] 1]
			if {[lindex [split $tag_end .] 0] > $current_line} {
			    set current_line [expr [lindex [split $tag_end .] 0] -1 ]
			    break
			}
                    } elseif {$char == "'"} {
                        set tag_end [add_multiline_tag $entry string {[^\\]'} $current_line.$x 0 2]
			set x [lindex [split $tag_end . ] 1]
			if {[lindex [split $tag_end .] 0] > $current_line} {
			    set current_line [expr [lindex [split $tag_end .] 0] -1]
			    break
			}
                    } elseif {[ string first $char "<ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789_$/*?" ] != -1} {
                        if {$word == ""} {
                            set start_pos $x
                        }
                        append word $char
                    } else {
                        if {$word != "" } {
                            add_color_tag $entry $current_line $start_pos $word
                            set word ""
                        }
                        if {[ string first $char "{}()\[\]" ] != -1 } {
                            $entry tag add brace $current_line.$x "$current_line.${x}+1c"
                        }
                    }
                }
            }
            incr current_line
        }
    }

    proc is_in_tag { tag_name entry position } {
        foreach pos [list [$entry tag ranges $tag_name]] {
            foreach {begin end} [lindex [split $pos " "]] {
                if {$end != ""} {
                    if { $position >= $begin && $position <= $end} {
                        return [list $begin $end $tag_name]
                    }
                }
            }
        }
        return 0
    }

    proc add_multiline_tag { entry tag exp start_pos delta_s delta_e} {
        set tag_end [ $entry search -regexp "$exp" [$entry index "$start_pos+1c"] end ]
	set start_pos [$entry index "$start_pos-${delta_s}c"]

        if {$tag_end == "" } {
            set tag_end [ $entry index end ]
        } else {
            set tag_end [$entry index "$tag_end + ${delta_e}c"]
        }

        $entry tag add $tag $start_pos $tag_end	
        return [$entry index "$tag_end+1c"]
    }

    proc add_color_tag { entry line start word } {
        global editor
        global highlight_groups

        if {[string range $word 0 0] == "$"} {
            #$entry tag add variable $line.$start $line.[expr $start + [string length $word]]
            $entry tag add variable $line.$start "$line.$start +1c wordend"
        }

        foreach tag [array names highlight_groups] {
            foreach w $editor($entry.$tag) {
                if {$word == $w } {
                    #set end [expr [string length $word] + $start]
                    $entry tag add $tag $line.$start "$line.$start +1c wordend"
                }
            }
        }
    }

    proc highlight_all {entry} {
        global editor
        global highlight_groups
        
        foreach tag [array names highlight_groups] {
            set pattern \{[regsub -all -- { } [string trim $editor($entry.$tag)] " | "]\}

            set point_list [$entry search -all -overlap -regexp $pattern 0.0 end]
            foreach point $point_list {
                $entry tag add $tag [$entry index $point] [$entry index "$point+1c wordend"]
            }
        }
        return
    }
    
    proc handle_console { out } {
        set status [ catch { gets $out line } result ]
        if { $status != 0 } {
            write_console $result
        } elseif { $result >= 0 } {
            write_console $line
        } elseif { [ eof $out ] } {
            close_console $out 
        } elseif { [ fblocked $out ] } {
            # nop
        }
    }

    proc tab_change { entry } {
        get_class_structure $entry
    }

    proc run_console { cmd } {
        ::system::windows::get_console
        write_console "[ system::config::get_magento_dir ]\$ [ string trimleft $cmd | ]\n"
        set out [ open $cmd ]
        fileevent $out readable [ list ::system::utils::handle_console $out ]
        fconfigure $out -blocking 0
    }

    proc close_console { out } {
        fconfigure $out -blocking true
        if { [ catch { close $out } error ] } {
            write_console $error
        }
    }

    proc write_console { text } {
        $::system::windows::cmd_console configure -state normal
        $::system::windows::cmd_console insert end "$text\n"
        $::system::windows::cmd_console see end
        $::system::windows::cmd_console configure -state disabled
    }

    proc close_window {} {
        global editor
        set entry [ .root.pnd.notebook select ]
        if {[$entry edit modified] == 1} {
            set reply [tk_dialog .foo "Save file" "File was modified. Save before close?" questhead 0 Yes No Cancel]
            if {$reply == 0} {
                set file_name $editor($entry,file_path)
                save_file $file_name $entry
            } elseif {$reply == 2} {
                return
            }
        }
        .root.status.position configure -text " "
        .root.pnd.left.bottom delete [.root.pnd.left.bottom children {}]
        destroy $entry
    }

    proc save_as_file {} {
        global editor
        set entry [.root.pnd.notebook select]
        set file_name [tk_getSaveFile -title [mc "Save as..."] -initialdir [file dirname $editor($entry,file_path)] -initialfile $editor($entry,file_name) -filetypes {}]
        if {$file_name != ""} {
            save_file $file_name $entry
            set editor($entry,file_path) $file_name
            set editor($entry,file_name) [file tail $file_name]
            .root.pnd.left.top delete [ .root.pnd.left.top children {} ]            
            fill_directory_tree
        }
    }

    proc save_file {{file_name ""} {entry ""}} {
        global load_path
        global editor

        if {$entry == ""} {
            set entry [lindex [.root.pnd.notebook tabs] [.root.pnd.notebook index current]]
        }

        if {$file_name == ""} {
            set file_name $editor($entry,file_path)
        }

        set backup [file normalize [join [list $load_path /var/backup/ [clock format [clock seconds] -format "%Y%m%d-%H%S-"] [file tail $file_name]] "" ]]
        set file_data [get_file_content $file_name]

        set back_data [open $backup w+]
        puts $back_data $file_name
        puts -nonewline $back_data $file_data
        close $back_data
        set f [ open $file_name w+ ]
        puts -nonewline $f [$entry get 1.0 end]
        close $f
        $entry edit modified 0
        .root.pnd.notebook tab $entry -text [file tail $file_name]
    }

    proc my_exit {} {
        global editor
        set reply 100
        set session {}
        
        foreach item [.root.pnd.notebook tabs ] {
            if { [$item edit modified] == 1 } {
                .root.pnd.notebook select $item
                if {$reply != 1} {
                    set reply [tk_dialog .foo "Save file" "File was modified. Save before close?" questhead 0 Yes {Save All} No Cancel]
                    if {$reply == 0 || $reply == 1} {
                        set file_name $editor($item,file_path)
                        save_file $file_name $item
                    } elseif {$reply == 3} {
                        return
                    }
                } else {
                    set file_name $editor($item,file_path)
                    save_file $file_name $item
                }
            }

            lappend session $editor($item,file_path):[$item index insert]
        }
        ::system::config::save_session $session
        exit
    }

    proc open_file { message file_path file_mask } {
        set file_name [tk_getOpenFile -title [mc $message] -initialdir $file_path -initialfile $file_mask -filetypes {}]
        return $file_name
    }

    proc check_used { entry line } {
        global editor

        set class [string trim [lindex [split $line " "] 0]]
        foreach used $editor($entry.used) {
            if {$class == [string trim [lindex $used 1]]} {
                set class [string trim [lindex $used 0]]
                break
            }
        }
        return $class
    }

    proc get_class_structure { entry } {
        global editor

        if {[array get editor $entry,file_name] == ""} {
            return
        }

        ::system::windows::add_progress 100
        update

        set editor($entry.functions) {}
        set editor($entry.variables) {}
        set editor($entry.constants) {}
        set editor($entry.structure) {}
        set editor($entry.parent) {}
        set editor($entry.used) {}
        set line_index 1
        set last_line [lindex [split [$entry index end] .] 0]
        set filename $editor($entry,file_path)
        set parent ""
        
        set current_point [.root.pnd.left.bottom insert {} end -text $editor($entry,file_name) -values [list $editor($entry,file_path)] -open true]

        while {$line_index <= $last_line} {
            update
            set line [string trim [$entry get $line_index.0 $line_index.end]]
            set first [string trim [lindex [split $line " "] 0]]
            if {$first == "use" } {
                set class_name [string trim [lindex [split $line " "] 1] " ;"]
                set as [string trim [lindex [split $line " "] 3] " ;"]
                if {$as == ""} {
                    set as [string trim [lindex [split $line "\\"] end] " ;"]
                }
                lappend editor($entry.used) [list $class_name $as]
            } elseif {$first == "class" || $first == "abstract"} {
                set parent [lindex [split $line " "] 3]
                if {[lindex [split $parent "\\"] 1] == ""} {
                    foreach uses [list $editor($entry.used)] {
                        if {[lindex [split $uses " "] 1] == $parent} {
                            set parent [system::magento::get_file_by_class_name [lindex [split $uses " "] 0]]
                        }
                    }
                } else {
                    set parent [::system::magento::get_file_by_class_name $parent]
                }
            } elseif {[string trim [lindex [split $line " "] 2] " ("] == "__construct"} {
                set construct_end [$entry search -exact ")" $line_index.0 end]
                if {$line_index == [lindex [split $construct_end .] 0]} {
                    set line [string trim $line ")"]
                    foreach param [split $line ","] {
                        set class_name [check_used $entry $param]
                        set class [::system::magento::get_file_by_class_name $class_name]
                        set varname [lindex [split $param " "] 1]
                        set editor($entry.$varname) $class
                    }
                } else {
                    while {$line_index <= [lindex [split $construct_end .] 0]} {
                        incr line_index
                        set line [string trim [$entry get $line_index.0 $line_index.end] " ,"]
                        if {[string range $line 0 0] != ")"} {
                            set class_name [check_used $entry $line]
                            set class [::system::magento::get_file_by_class_name $class_name]
                            set varname [lindex [split $line " "] 1]
                            set editor($entry.$varname) $class
                        } else {
                            break
                        }
                    }
                    break
                }
            }
            incr line_index
        }

        set editor($entry.parent) $parent

        set file_data [get_file_data $filename]

        set const [lindex $file_data 0]
        set var [lindex $file_data 1]
        set func [lindex $file_data 2]

        set editor($entry.constants) $const
        set editor($entry.variables) $var
        set editor($entry.functions) $func

        add_tree .root.pnd.left.bottom $current_point $editor($entry.constants)
        add_tree .root.pnd.left.bottom $current_point $editor($entry.variables)
        add_tree .root.pnd.left.bottom $current_point $editor($entry.functions)

        bind .root.pnd.left.bottom <Double-1> {::system::utils::goto_line [.root.pnd.left.bottom set [%W focus] line_no]}
        ::system::windows::remove_progress
    }

    proc get_file_data { filename } {

        set functions {}
        set variables {}
        set constants {}
        set parent ""
        
        set file_data [get_file_content $filename]
        set line_index 1

        foreach line [split $file_data "\n"] {
            update

            set line [string trim $line]
            set index 0

            if {[string trim [lindex [split $line " "] 0]] == "abstract"} {
                set index 1
            }
            
            set vis [string trim [lindex [split $line " "] $index]]
            set var [string trim [lindex [split $line " "] [expr $index + 1]] " =;("]
            set func [string trim [lindex [split $line " "] [expr $index + 2]] " "]
            set func_static [string trim [lindex [split $line " "] [expr $index + 3]] " "]

            if {$func == "extends"} {
                set parent $func_static
            }

            if {$var == "function"} {
                lappend functions [list [string trim [lindex [split $line ")"] 0]]\) $line_index $filename]
            }

            if {$func == "function"} {
                lappend functions [list [string trim [lindex [split $line ")"] 0]]\) $line_index $filename]
            }

            if {[string range $var 0 0] == "$"} {
                if {$vis == "public" || $vis == "protected" || $vis == "private"} {
                    if {[string first = $line] != -1} {
                        lappend variables [list [string trim [lindex [split $line "="] 0]] $line_index $filename]
                    } else {
                        lappend variables [list [string trim [lindex [split $line ";"] 0]] $line_index $filename]
                    }
                }
            } 

            if {[string range $func 0 0] == "$"} {
                if {$var == "static"} {
                    if {[string first = $line] != -1} {
                        lappend variables [list [string trim [lindex [split $line "="] 0]] $line_index $filename]
                    } else {
                        lappend variables [list [string trim [lindex [split $line ";"] 0]] $line_index $filename]
                    }
                }
            } 
                
            if {$vis == "const"} {
                set var "$vis $var"
                lappend constants [list [string trim [lindex [split $line ";"] 0]] $line_index $filename]
            }
            incr line_index
        }
        set data [list $constants $variables $functions $parent]
        return $data
    }

    proc add_tree {entry current list} {
        foreach item $list {
            $entry insert $current end -text [lindex $item 0] -values [list [lindex $item 2] [lindex $item 1]]
        }
    }

    proc goto_line {{ line_no 1 }} {
        [.root.pnd.notebook select ] mark set insert $line_no.0
        [.root.pnd.notebook select ] see $line_no.0
        focus -force [.root.pnd.notebook select]
    }

    proc handle_autocomplete { entry key } {
    }

    proc get_func_var_list { entry pattern } {
        global editor
        global parsed_data

        if { [winfo exists .autocomplete] == 1 } {
            destroy .autocomplete
        }

        set keyword [$entry get [$entry index "insert-3c wordstart"] [$entry index "insert-2c"]]

        if {[string trim $keyword] == ""} {
            set pos [$entry search -backwards -exact "$" [$entry index insert]]
            set keyword [$entry get "$pos+1c" "$pos+1c wordend"]
        }

        set key "$editor($entry,file_path).$$keyword"
        set class_name  [string trimleft [string trim [lindex [array get parsed_data $key] 1]] "\\"]
        set class [::system::magento::get_file_by_class_name $class_name]
        if {$class == ""} {
            set key "$editor($entry,file_path).$class_name"
            set class_name  [string trimleft [string trim [lindex [array get parsed_data $key] 1]] "\\"]
            set class [::system::magento::get_file_by_class_name $class_name]
            if {$class == ""} {
                set pos [$entry search -backwards -exact "$" [$entry index insert]]
                set keyword [$entry get "$pos+1c" "insert-2c"]
                set key "$editor($entry,file_path).$$keyword"
                set class_name  [string trimleft [string trim [lindex [array get parsed_data $key] 1]] "\\"]
                set class [::system::magento::get_file_by_class_name $class_name]
                if {$class == ""} {
                    set key "$editor($entry,file_path).$class_name"
                    set class_name  [string trimleft [string trim [lindex [array get parsed_data $key] 1]] "\\"]
                    set class [::system::magento::get_file_by_class_name $class_name]
                    if {$class == ""} {
                        return
                    }
                }
            }
        }

        set var_list [get_file_data $class]
        set vars [lindex $var_list 1]
        set func [lindex $var_list 2]
        set parent [lindex $var_list 3]

        while {$parent != ""} {
            set class [::system::magento::get_file_by_class_name $parent]
            if {$class != ""} {
                set parent_list [get_file_data $class]

                set vars [concat $vars [lindex $parent_list 1]]
                set func [concat $func [lindex $parent_list 3]]
                set parent [lindex $parent_list 3]
            } else {
                set parent ""
            }
        }

        menu .autocomplete -tearoff 0 -relief flat -background yellow -activebackground magenta1 -activeborderwidth 0

        # return

        set pop_items {}
        
        foreach item $vars {
            set word [lindex [split [lindex $item 0] "$"] 1]
            .autocomplete add command -label [lindex $item 0] -command "$entry insert [$entry index insert] $word"
            #lappend pop_items [lindex [split [lindex $item 0] " "] 1]
            #::system::windows::popup_add [lindex [split [lindex $item 0] " "] 1]
        }

        .autocomplete add separator

        foreach item $func {
            set funcname [lindex $item 0]
            set func_line [lindex $item 1]
            set func_file [lindex $item 2]
            if {$func_line != ""} {
                .autocomplete add command -label [lindex $item 0] -command "::system::utils::insert_function $entry {$funcname} $func_line $func_file"
                #::system::windows::popup_add [lindex [split [lindex $item 0] " "] 2]
                #lappend pop_items [lindex [split [lindex $item 0] " "] 2]
            }
        }

        #::system::windows::get_popup $entry
        #::system::windows::popup_add $pop_items        
        if {[.autocomplete index end] > 0} {
            tk_popup .autocomplete 350 100
        }
    }

    proc get_const_list { entry pattern } {
        global editor

        if { [winfo exists .autocomplete] == 1 } {
            destroy .autocomplete
        }

        set keyword [string trim [$entry get [$entry search -exact -backwards " " [$entry index insert-2chars]] [$entry index insert-2chars]]]
        menu .autocomplete -tearoff 0 -relief flat -background yellow -activebackground magenta1 -activeborderwidth 0

        if {$keyword == {self}} {
            set const $editor($entry.constants)
            set vars $editor($entry.variables)
            set func $editor($entry.functions)
        } else {
            set class_name [check_used $entry $keyword]
            set class [::system::magento::get_file_by_class_name $class_name]
            set var_list [get_file_data $class]
            set const [lindex $var_list 0]
            set vars [lindex $var_list 1]
            set func [lindex $var_list 2]
        }

        foreach item $const {
            set word [lindex [split [lindex $item 0] " "] 1]
            .autocomplete add command -label [lindex $item 0] -command " $entry insert [$entry index insert] $word "
        }

        foreach item $vars {
            set word [lindex [split [lindex $item 0] "$"] 1]
            .autocomplete add command -label [lindex $item 0] -command " $entry insert [$entry index insert] $word "
        }

        .autocomplete add separator

        foreach item $func {
            set funcname [lindex $item 0]
            set func_line [lindex $item 1]
            set func_file [lindex $item 2]
            if {$func_line != ""} {
                .autocomplete add command -label [lindex $item 0] -command "::system::utils::insert_function $entry {$funcname} $func_line $func_file"
            }
        }

        if {[.autocomplete index end] > 0} {
            tk_popup .autocomplete 350 100
        }
    }

    proc insert_function {entry name line where} {

        set data [get_file_content $where]
        set current 1
        set retvalue ""

        foreach curr_line [split $data "\n"] {
            if {$current == $line} {
                set retvalue [string range $curr_line [expr [string last "function" $curr_line] + 9] end]
                break
            }
            incr current
        }
        $entry insert [ $entry index insert ] "$retvalue"
    }

    proc format_block {entry {start_line 0} {end_line 0}} {
        format_paragraph $entry brace $start_line $end_line
    }
    
    proc format_paragraph {entry type start_line end_line} {

        set position_left  [$entry search -exact -backwards "\{" [$entry index insert]]
        set position_right [$entry search -exact -backwards "\}" [$entry index insert]]
        set test_symbol "\}"
        set tab 4

        if {$position_left == ""} {
            set position_left 0.0
        }

        if {$position_right == ""} {
            set position_right [$entry index insert ]
        }
        

        if {$position_right > $position_left} {
            set delta 0
            set position $position_right
        } else {
            set delta 1
            set position $position_left
        }

        set braces_line_no [lindex [split $position .] 0]
        set braces_line [$entry get $braces_line_no.0 $braces_line_no.end ]
        set braces_line_trimmed [string trimleft $braces_line]
        set spaces [expr [string length $braces_line] - [string length $braces_line_trimmed]]
        set add_empty_line 0
        set final_line [lindex [split [$entry index insert] .] 0]
        
        incr braces_line_no

        while {$braces_line_no <= $final_line} {
            set current_line [$entry get $braces_line_no.0 $braces_line_no.end]
            set current_line_trimmed [string trimleft $current_line]

            if {[string range $current_line_trimmed 0 0] == $test_symbol} {
                set add_empty_line 1
                if {$delta > 0} {
                    incr delta -1
                }
            } elseif {[string range $current_line_trimmed 0 0] == "\)" || [string range $current_line_trimmed 0 0] == "\]"} {
                if {$delta > 0} {
                    incr delta -1
                }
            }

            $entry delete $braces_line_no.0 $braces_line_no.end

            if {$add_empty_line == 1} {
                $entry insert $braces_line_no.0 [string repeat " " [expr $spaces + $tab]]\n
                incr final_line
                incr braces_line_no
            }
            
            $entry insert $braces_line_no.0 [string repeat " " [expr $spaces + $tab * $delta]]$current_line_trimmed

            if {[string first {(} $current_line_trimmed] != -1} {
                incr delta
            }

            if {[string first {[} $current_line_trimmed] != -1} {
                incr delta
            }

            if {[string first {)} $current_line_trimmed] != -1} {
                if {$delta > 0} {
                    incr delta -1
                }
            }

            if {[string first {]} $current_line_trimmed] != -1} {
                if {$delta > 0} {
                    incr delta -1
                }
            }

            if {$braces_line_no == $final_line && $add_empty_line == 1} {
                $entry mark set insert [expr $braces_line_no - 1].end
            }
            set add_empty_line 0
            
            incr braces_line_no
        }

        highlight_text $entry 
    }

    proc fill_history {} {
        global load_path

        .history_tree delete [.history_tree children {}]

        set file_list [lsort -ascii [glob -nocomplain -tails -directory [join [list $load_path /var/backup/] "" ] * ]]

        set dir ""
        set entry {}
        
        foreach history_file [split $file_list " "] {
            set real_dir [lindex [split $history_file "-"] 0]
            if {$dir != $real_dir} {
                set entry [.history_tree insert {} end -text $real_dir ]
                set dir $real_dir
            }

            set filename [file normalize "$load_path/var/backup/$history_file"]
            set fp [open $filename r]
            set real_path [lindex [split [read $fp] "\n"] 0]
            close $fp
            
            .history_tree insert $entry end -text [lindex [split $history_file "-"] 2] -values [list [lindex [split $history_file "-"] 1] $real_path $filename]
        }
    }

    proc handle_history_treeview_select {entry} {
        global load_path

        .history_viewer delete 0.0 end
        
        set history_file [.history_tree set $entry saved_path]
        set real_file [.history_tree set $entry real_path]
        set diff_file $load_path/var/history.diff

        if {[file exists $diff_file] == 1} {
            file delete $diff_file
        }

        catch {exec diff -up $history_file $real_file > $diff_file} retvalue

        if {[file exists $diff_file] == 1} {
            set fp [open $diff_file r]
            set data [read $fp]
            close $fp

            .history_viewer insert 0.0 $data
            #.history_viewer delete 0.0 2.end
            set i 1
            while {$i <= [lindex [split [.history_viewer index end] . ] 0]} {
                if { [string range [.history_viewer get $i.0 $i.end] 0 0] == "-" } {
                    .history_viewer tag add removed $i.0 $i.end
                } elseif { [string range [.history_viewer get $i.0 $i.end] 0 0] == "+" } {
                    .history_viewer tag add added $i.0 $i.end
                }
                incr i
            }

            .history_viewer tag configure removed -background red
            .history_viewer tag configure added -background green           

            .history_viewer mark set insert 0.0
        }
    }

    proc get_file_content {filename} {
        if {[file exists $filename] == 0} {
            return false
        }

        set fp [open $filename r]
        set data [read $fp]
        close $fp

        return $data
    }

    proc minus {line part} {
        return [string map {$part ""} $line]
    }
}
