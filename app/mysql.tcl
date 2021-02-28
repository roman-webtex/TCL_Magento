# Tcl/Tk Magento Helper                
# Distrubuted under GPL               
# Copyright (c) "Roman Dmytrenko", 2020       
# Author: Roman Dmytrenko roman.webtex@gmail.com 
#
#
# Mysql Adapter
#
namespace eval ::system::sql::mysql {

    global connection
    variable result ""
    
    proc create_config_connection {{file_name ""}} {
        global connection
        set connection(adapter) {}
        set connection(port) 3305
        
        if { $file_name == "" } {
            set filename [::system::config::get_magento_dir]/app/etc/env.php
        }

        set data [::system::utils::get_file_content $filename]

        foreach line [ split $data "\n" ] {
            set line [regsub -all -- {\s+} $line ""]
            set name [string trim [lindex [split $line "="] 0] "'\""]
            set value [string range [string trim [lindex [split $line "="] 1]] 2 end-2]

            switch -- $name {
                table_prefix {
                    set connection(prefix) $value
                }
                host {
                    set connection(host) [lindex [split $value ":"] 0]
                    if {[lindex [split $value ":"] 1] != ""} {
                        set connection(port) [lindex [split $value ":"] 1]
                    }
                }
                dbname {
                    set connection(dbname) $value
                }
                username {
                    set connection(user) $value
                }
                password {
                    set connection(password) $value
                }
            } 
        }
    }

    proc create_param_connection {{user root} {password 12345} {dbname mysql} {host localhost} {port 3305} {prefix ""}} {
        global connection
        
        set connection(user) $user
        set connection(password) $password
        set connection(dbname) $dbname
        set connection(host) $host
        set connection(port) $port
        set connection(prefix) $prefix
    }

    
    proc dbopen {} {
        global connection
        variable result
        
        set result 1
        if {[catch {set connection(adapter) [mysqlconnect -host $connection(host) -port $connection(port) -user $connection(user) -password $connection(password) -db $connection(dbname)]} cerr]} {
            set connection(adapter) {}
            set result 0
        }
        return $result
    }

    proc dbclose {} {
        global connection
        
        mysqlclose
        set connection(adapter) {}
    }

    proc run { sql { command select }  {type -list} } {
        global connection
        variable result
        
        set result {}
        if {[dbopen] != 0} {
            switch -- $command {
                select {
                    set result [mysqlsel $connection(adapter) $sql $type]
                }
                use {
                    set result [mysqluse $connection(adapter) $sql]
                }
                exec {
                    set result [mysqlexec $connection(adapter) $sql ]
                }
            }
            dbclose
        }
        return $result
    }

    proc select { sql { type -list } } {
        return [run $sql select $type ]
    }

    proc insert { sql } {
        return [run $sql exec]
    }

    proc exec { sql } {
        return [run $sql exec ]
    }

    proc get_field_value {table retval field value} {
        global connection

        create_config_connection
        set sql "select `$retval` from $connection(prefix)$table where `$field`='$value'"
        return [lindex [run $sql select -flatlist] 0]
    }
}
