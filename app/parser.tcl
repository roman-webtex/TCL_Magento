# Tcl/Tk Magento Helper                
# Distrubuted under GPL               
# Copyright (c) "Roman Dmytrenko", 2020       
# Author: Roman Dmytrenko roman.webtex@gmail.com 
#
# file parser
#
namespace eval system::parser {

    proc parse_php {filename} {
        global parsed_data

        #array unset parsed_data
        set file_data [string map {"<?php" ""} [regsub -all {\s+} [::system::utils::get_file_content $filename] " "]]
        regsub -all {/\*.*?\*/} $file_data {} file_data
        set file_data [string map {";" ";\n" "{" "\n{\n" "}" "\n}\n" } $file_data ]

        set lineno 1;

        foreach line [split $file_data "\n"] {
            update
            set line [string trim [string map { \
                                       "public function" "function" \
                                       "private function" "function" \
                                       "protected function" "function" \
                                       "abstract" "" \
                                       "public" "variable" \
                                       "private" "variable" \
                                       "protected" "variable" \
                                                } $line]]

            #puts $line
            set 1 [lindex [split $line " "] 0]
            set 2 [lindex [split $line " "] 1]
            set 3 [lindex [split $line " "] 2]
            set 4 [lindex [split $line " "] 3]

            if {$1 == {namespace}} {
                set parsed_data($filename.namespace) [string trimright $2 " ;"]
            } elseif {$1 == "use"} {
                set parsed_data($filename.[string trimright $2 " ;"]) [string trimright $2 " ;"]
                if {$3 != ""} {
                    set parsed_data($filename.[string trimright $4 " ;"]) [string trimright $2 " ;"] 
                } else {
                    set parsed_data($filename.[string trimright [lindex [split $2 "\\"] end] " ;"]) [string trimright $2 " ;"]
                }
                #puts [::system::utils::minus $line "use"]
            } elseif {$1 == "function"} {
                if {[string trim [lindex [split $2 "("] 0]] == "__construct"} {
                    set constructor [string trim [string trimright [lindex [split $line "("] 1] ")"]]
                    foreach classline [split $constructor ","] {
                        set class [lindex [split [string trim [lindex [split $classline "="] 0]] " "] 0]
                        set variable [lindex [split [string trim [lindex [split $classline "="] 0]] " "] 1]
                        set parsed_data($filename.$variable) $class
                    }
                } else {
                    #set parsed_data($filename.function.$lineno) [string trimright $2 " ;"]
                }
            } elseif {$1 == "variable"} {
                #set parsed_data($filename.[string trimright $2 " ;"]) ""
            } elseif {$1 == "const"} {
                set parsed_data($filename.[string trimright $2 " ;"]) [string trimright $4 " ;"]
            } elseif {$1 == "class"} {
                set class $parsed_data($filename.namespace)\\[string trimright $2]
                set parsed_data($filename.\$this) $class
                set parsed_data($filename.$class) $class
                set parsed_data($filename.\$parent) [string trimright $4]
            } elseif {[string range $1 0 6] == {$this->}} {
                if {[string range $3 end end] == ";"} {
                    set parsed_data($filename.$[string range $1 1 end]) [string trim $3 " ;"]
                }
            }

            incr lineno
        }
    }
}
