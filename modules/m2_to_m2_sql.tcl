# Tcl/Tk Magento Helper                
# Distrubuted under GPL               
# Copyright (c) "Roman Dmytrenko", 2020       
# Author: Roman Dmytrenko roman.webtex@gmail.com 
#
# Create sql script for transfer data from m2 instance to another one
# required mysqltcl package
# 
# db_from and db_to must be deployed in same MySql instance

namespace eval ::system::m2_to_m2_sql {
    global table_list
    global var_list

    #
    # for local MySql instance set host to loсalhost
    # for docker container instance set host to 127.0.0.1 and port 3305 (this working for me)
    #
    variable host 127.0.0.1
    variable port 3305
    variable username magento
    variable password magento
    variable db_from gelb_m2
    variable db_to magento
    variable store_id 1
    variable website_id 1

    proc init_data {} {
        global table_list
        global var_list

        #
        # variable list
        # need for save last id_field values
        #
        set var_list(quote.entity_id) 0
        set var_list(quote_item.item_id) 0
        set var_list(quote_address.address_id) 0
        set var_list(quote_address_item.address_item_id) 0
        set var_list(quote_payment.payment_id) 0
        set var_list(quote_shipping_rate.rate_id) 0
        set var_list(sales_order.entity_id) 0
        set var_list(sales_order_address.entity_id) 0
        set var_list(sales_order_item.item_id) 0
        set var_list(sales_order_payment.entity_id) 0
        set var_list(sales_order_tax.tax_id) 0
        set var_list(sales_order_grid.entity_id) 0
        set var_list(sales_payment_transaction.transaction_id) 0
        set var_list(sales_invoice.entity_id) 0
        set var_list(sales_invoice_item.entity_id) 0
        set var_list(sales_invoice_grid.entity_id) 0
        set var_list(sales_shipment.entity_id) 0
        set var_list(sales_shipment_item.entity_id) 0
        set var_list(sales_shipment_grid.entity_id) 0
        set var_list(sales_creditmemo.entity_id) 0
        set var_list(sales_creditmemo_grid.entity_id) 0
        set var_list(sales_creditmemo_item.entity_id) 0
        set var_list(sales_creditmemo_comment.entity_id) 0
        set var_list(customer_entity.entity_id) 0
        set var_list(customer_address_entity.entity_id) 0

        #
        # tables array
        # table_list(table_name) = "id_field[|||related_field|related_id_field|related_table[|...|...|...]]"
        #
        set table_list(customer_entity) "entity_id"
        set table_list(customer_address_entity) "entity_id|||parent_id|entity_id|customer_entity"
        set table_list(quote) "entity_id"
        set table_list(quote_item) "item_id|||quote_id|entity_id|quote"
        set table_list(quote_item_option) "option_id|||item_id|item_id|quote_item"
        set table_list(quote_payment) "payment_id|||quote_id|entity_id|quote"
        set table_list(quote_shipping_rate) "rate_id|||address_id|address_id|quote_address"
        set table_list(quote_address) "address_id|||quote_id|entity_id|quote"
        set table_list(quote_address_item) "address_item_id|||quote_address_id|address_id|quote_address"
        set table_list(sales_order) "entity_id|||customer_id|entity_id|customer_entity|billing_address_id|entity_id|sales_order_address|shipping_address_id|entity_id|sales_order_address"
        set table_list(sales_order_address) "entity_id|||parent_id|entity_id|sales_order|customer_address_id|entity_id|customer_address_entity|customer_id|entity_id|customer_entity"
        set table_list(sales_order_item) "item_id|||order_id|entity_id|sales_order|parent_item_id|item_id|sales_order_item|quote_item_id|item_id|quote_item"
        set table_list(sales_order_payment) "entity_id|||parent_id|entity_id|sales_order"
        set table_list(sales_order_status_history) "entity_id|||parent_id|entity_id|sales_order"
        set table_list(sales_order_tax) "tax_id|||order_id|entity_id|sales_order"
        set table_list(sales_order_tax_item) "tax_item_id|||tax_id|tax_id|sales_order_tax|item_id|item_id|sales_order_item"
        set table_list(sales_order_grid) "entity_id|||customer_id|entity_id|customer_entity"
        set table_list(sales_payment_transaction) "transaction_id|||parent_id|transaction_id|sales_payment_transaction|order_id|entity_id|sales_order|payment_id|entity_id|sales_order_payment"
        set table_list(sales_invoice) "entity_id|||order_id|entity_id|sales_order|shipping_address_id|entity_id|sales_order_address|billing_address_id|entity_id|sales_order_address"
        set table_list(sales_invoice_item) "entity_id|||parent_id|entity_id|sales_invoice|order_item_id|item_id|sales_order_item"
        set table_list(sales_invoice_grid) "entity_id|||order_id|entity_id|sales_order"
        set table_list(sales_creditmemo) "entity_id|||order_id|entity_id|sales_order|invoice_id|entity_id|sales_invoice|transaction_id|transaction_id|sales_payment_transaction"
        set table_list(sales_creditmemo_comment) "entity_id|||parent_id|entity_id|sales_creditmemo"
        set table_list(sales_creditmemo_item) "entity_id|||parent_id|entity_id|sales_creditmemo|order_item_id|item_id|sales_order_item"
        set table_list(sales_creditmemo_grid) "entity_id|||order_id|entity_id|sales_order"
        set table_list(sales_shipment) "entity_id|||order_id|entity_id|sales_order|customer_id|entity_id|customer_entity|shipping_address_id|entity_id|sales_order_address|billing_address_id|entity_id|sales_order_address"
        set table_list(sales_shipment_comment) "entity_id|||parent_id|entity_id|sales_shipment"
        set table_list(sales_shipment_item) "entity_id|||parent_id|entity_id|sales_shipment|order_item_id|item_id|sales_order_item"
        set table_list(sales_shipment_track) "entity_id|||parent_id|entity_id|sales_shipment|order_id|entity_id|sales_order"
        set table_list(sales_shipment_grid) "entity_id|||order_id|entity_id|sales_order"
    }

    proc db {base} {
        variable host
        variable port
        variable username
        variable password
        return [mysqlconnect -host $host -port $port -user $username -password $password -db $base]
    }

    proc max {field database} {
        variable db_to
        return "(select max($field) from ${db_to}.$database)"
    }

    proc max_val {field database} {
        variable db_to
        return [mysqlsel [db $db_to] "select max($field) from $database" -flatlist]
    }

    #
    # create field list
    # need because some tables may have different fields
    #
    proc field_names {table_name} {
        variable db_to
        variable db_from
        
        set res {}

        set from_names [mysqlcol [db $db_from] $table_name name]
        set to_names [mysqlcol [db $db_to] $table_name name]

        mysqlclose

        foreach name [list {*}$to_names] {
            if {[lsearch -exact $from_names $name] != -1} {
                lappend res $name  
            }
        }

        return $res
    }

    proc get_max_values {} {
        global var_list

        foreach name [array names var_list] {
            set table [lindex [split $name .] 0]
            set field [lindex [split $name .] 1]
            set var_list($name) [max_val $field $table]
        }
    }

    proc write_sql {file_data} {
        set fp [open "${::load_path}/var/out/transfer_2to2.sql" w]
        puts $fp $file_data
        close $fp
    }

    proc get_label {} {
        return [mc "Transfer M2 data to not empty M2 instance"]
    }

    proc run {} {
        global table_list
        global var_list
        
        variable db_to
        variable db_from
        variable store_id
        variable website_id

        set reply [tk_dialog .foo "Warning" "You must have working MySql instance with '$db_from' and '$db_to' databases deployed.\n Run script creation?" questhead 1 Yes No]
        switch -- $reply {
            1 {
                return 0
            }
        }
        set reply [tk_dialog .foo "Data transfere plugin" "All done. Open sql script in editor?" questhead 0 Yes No]
        switch -- $reply {
            0 {
                ::system::windows::edit_file dept_ident ${::load_path}/var/out/transfer_2to2.sql
                return 0
            }
            1 {
                return 0
            }
        }
       
        ::system::windows::add_progress

        init_data
        
        get_max_values

        update

        set sql "use ${db_to}\;\nSET sql_mode='ALLOW_INVALID_DATES'\;\nSET FOREIGN_KEY_CHECKS=0\;\n"

        append sql "-- create temporary tables and modify id fields\n"

        foreach tbl_name [array names table_list] {
            append sql "create temporary table " ${tbl_name}_tmp " select " [regsub -all -- " " [field_names $tbl_name] , ] " from " ${db_from}.$tbl_name \; \n
            foreach {field id_field relate_table} [split $table_list($tbl_name) | ] {
                if {$id_field == ""} {
                    append sql "update ${tbl_name}_tmp set $field = $field + [max $field $tbl_name] \;\n"
                } else {
                    append sql "update ${tbl_name}_tmp set $field = $field + $var_list(${relate_table}.${id_field}) \;\n"
                }
            }
            if {[lsearch -exact [field_names $tbl_name] website_id] != -1} {
                append sql "update ${tbl_name}_tmp set website_id = $website_id \;\n"
            }
            if {[lsearch -exact [field_names $tbl_name] store_id] != -1} {
                append sql "update ${tbl_name}_tmp set stote_id = $store_id \;\n"
            }
            append sql \n
            update
        }

        append sql "-- transfer data from temporary tables\n"

        foreach tbl_name [array names table_list] {
            set field_list [regsub -all -- " " [field_names $tbl_name] ,]
            append sql "insert into ${db_to}.$tbl_name ($field_list) select $field_list from ${tbl_name}_tmp" \;\n
            update
        }

        write_sql $sql

        ::system::windows::remove_progress

        set reply [tk_dialog .foo "Data transfere plugin" "All done. Open sql script in editor?" questhead 0 Yes No]
        switch -- $reply {
            0 {
                ::system::windows::edit_file dept_ident ${::load_path}/var/out/transfer_2to2.sql
                return 0
            }
            1 {
                return 0
            }
        }
    }
}
