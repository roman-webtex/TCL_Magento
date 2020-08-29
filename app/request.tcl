#
# MySql Request
#
namespace eval ::system::sql::request {

    variable sql ""
    array set fields {}
    array set from {}
    array set where {}
    variable distinct 0
    variable model ""
    array set db_schema {}

    proc init {entity} {
        variable db_schema
        global config

        set default_fields [::system::magento::get_default_fields $entity]

        

#       set db_schema_file $module_dir/etc/db_schema_whitelist.json
#
#       if {[file exists $db_schema_file] == 1} {
#           set db_schema_list [regsub -all -- {[,:]} [::system::utils::get_file_content $db_schema_file] ""]
#       }
#
#       foreach {table data} [lindex $db_schema_list 0] {
#           puts $table
#           foreach {column enabled} [lindex $data 1] {
#               puts $column
#           }
#       }
    }

    proc add_field { field {as ""} } {

        if {$as == ""} {set as $field}
        
        array set fields($field) $as
    }

    proc add_from { table { as ""} {condition ""} } {

        if {$as == ""} {set as $table}
        
        array set from($table) $as

        if {$condition != ""} {
            array set where()
        }
    }

    proc add_condition {} {
        
    }
}
