# magento common command

namespace eval system::magento {

    variable di_fields_type

    proc admin_create {} {
	dict set admin_config admin-firstname "Admin"
	dict set admin_config admin-lastname "Magento"
	dict set admin_config admin-email "admin@local.magento.com"
	dict set admin_config admin-name "admin"
	dict set admin_config admin-password "admin123123"
	set command "| [ system::config::get_magento_dir ]/bin/magento admin:user:create "
	prepare_and_run $command [ ::system::windows::get_params_window $admin_config ]
    }
    
    proc setup_install {} {
	dict set install_config db-host "localhost"
	dict set install_config db-name "magento"
	dict set install_config db-user "magento"
	dict set install_config db-password "magento"
	dict set install_config base-url "http://local.magento2.com/"
	dict set install_config base-url-secure "https://local.magento2.com/"
	dict set install_config backend-frontname "admin"
	dict set install_config admin-firstname "Admin"
	dict set install_config admin-lastname "Magento"
	dict set install_config admin-email "admin@local.magento.com"
	dict set install_config admin-name "admin"
	dict set install_config admin-password "admin123123"
	dict set install_config use-sample-data 0
	set command "| [ system::config::get_magento_dir ]/bin/magento setup:install "
	prepare_and_run $command [ ::system::windows::get_params_window $install_config ]
    }

    proc setup_upgrade {} {
	set cmd "| [ system::config::get_magento_dir ]/bin/magento setup:upgrade"
	system::utils::run_console $cmd
    }

    proc setup_di_compile {} {
	set cmd "| [ system::config::get_magento_dir ]/bin/magento setup:di:compile"
	system::utils::run_console $cmd
    }

    proc setup_deploy {} {
	set cmd "| [ system::config::get_magento_dir ]/bin/magento setup:static-content:deploy -f"	
	system::utils::run_console $cmd
    }

    proc prepare_and_run { cmd params } {
	dict for { key value } $params {
	    if { $value == 1 } {
		set cmd "$cmd --$key"
	    } elseif { $value != 0 } {
		set cmd "$cmd --$key $value"
	    }
	}
	system::utils::run_console $cmd
    }

    proc get_module_dir_by_class_name { class_name } {
	set class_file [get_file_by_class_name $class_name]
	return [regsub -- {/Model.*$} $class_file "/"]
    }

    proc get_file_by_class_name { class_name } {

	set magento_dir [::system::config::get_magento_dir]
	set class_name [string map {Factory ""}  $class_name]
	set file_name ""

	set psr4namespace [ get_namespace_from_configs $class_name]

	regsub -all -- {\\} $class_name.php "/" class_name
	regsub -all -- "-" $class_name "" class_name
	set class_name [string trim $class_name "/"]

	set rest_part [lrange [split $class_name "/"] 2 end]
	regsub -all " " $rest_part "/" rest_part

	if {$psr4namespace != ""} {
	    foreach path [split $psr4namespace " "] {
	        if {[file exists $path/$rest_part] != 0} {
		    set file_name $path/$rest_part
		}
	    }
	} elseif {[file exists $magento_dir/app/code/$class_name] != 0} {
	    set file_name $magento_dir/app/code/$class_name
	} else {
	    set vendor [string tolower [lrange [split $class_name "/"] 0 0]]
	    set namespace [string tolower [lrange [split $class_name "/"] 1 1]]
	    set file_name $magento_dir/vendor/$vendor/$namespace/$rest_part

	    if {[file exists $file_name] == 0} {
		set namespace "module-$namespace"
		set file_name $magento_dir/vendor/$vendor/$namespace/$rest_part
	    }

	    if {[file exists $file_name] == 0} {
		set file_name ""
	    }
	}
	return $file_name
    }

    proc get_namespace_from_configs {class_name} {
	set psr4config [::system::config::get_magento_dir]/vendor/composer/autoload_psr4.php

	set fp [open $psr4config]
	set psr4data [read $fp]
	close $fp

	set baseDir [::system::config::get_magento_dir]
	set vendorDir $baseDir/vendor
	set test [lindex [split $class_name "\\"] 0]\\[lindex [split $class_name "\\"] 1]\\

	foreach line [split $psr4data "\n"] {
	    
	    set namespace [string trim [string trim [lindex [split $line ">"] 0] " ="] "'"]
	    regsub -all -- {\\\\} $namespace {\\} namespace
   
	    set namespace_path [string trim [lindex [split $line ">"] 1]]
	    regsub -all -- {[\'\(\)\.\,\s]+} $namespace_path " " namespace_path
	    set namespace_path [lrange [split [string trim $namespace_path] " "] 1 end]
	    set result ""
  
	    if { $namespace == $test } {
		foreach {prefix path} [split $namespace_path " "] {
		    set prefix [string trim $prefix {\}\{}]
		    lappend result [eval "join $prefix$path"]
		}
		break
	    }
	}
	return $result
    }

    proc module_create {} {

    }

    proc module_open {} {
	if {[set file_name [::system::utils::open_file "Select module registration.php" [::system::config::get_magento_dir] "registration.php" ]] != ""} {
	    
	}
    }

    proc get_entity_id {{type product}} {
	variable $type

	
	set sql "select entity_type_id from eav_entity_type"
	
	
    }

    proc mysql {} {
#	::system::mysql::create_config_connection
#	set res [::system::mysql::select {select * from core_config_data; }]
	#	puts $res
	::system::sql::request::init {\Magento\Catalog\Model\Product}
    }

    proc get_default_fields {entity} {
	set model [::system::sql::mysql::get_field_value eav_entity_type entity_model entity_type_code $entity]
	
	set module_dir [::system::magento::get_module_dir_by_class_name $model]
	set di_file $module_dir/etc/di.xml

	foreach line [split $di_file "\n"] {
	    
	}

    }

    proc add_model {} {
	::system::windows::get_model_window
    }

    proc get_db_field_types {} {
	set result {}
	set di_file [::system::config::get_magento_dir]/app/etc/di.xml
	set file_data [::system::utils::get_file_content $di_file]

	set doc [dom parse $file_data]
	set root [$doc documentElement]
	set node [$root selectNodes {/config/type/arguments/argument[@name='typeFactories']}]
	set child_nodes [$node selectNodes item]

	foreach item $child_nodes {
	    lappend result [lindex [split [lindex [$item selectNodes attribute::name] 0] " "] 1]
	}

	return $result
    }

    proc create_comment {model vendor module} {
	return "\n/** \n * @category [regsub -- {_Model.*$} $model {}]\n * @author $vendor Team\n * @copyright Copyright © [clock format [clock seconds] -format %Y ] $vendor \n * @package [regsub -- {_Model.*$} $model {}]\n */ \n"
    }

    proc create_model {m_name table} {
	global field_no
	global fields_list

	::system::windows::add_progress
	
	set name [regsub -all -- _ $m_name /]
	set full_name [::system::config::get_magento_dir]/app/code/$name.php
	set model_file_name [file tail $full_name]
	set model_template [string range $model_file_name 0 end-4]
	set created_name [::system::config::get_magento_dir]/app/code
	set vendor [lindex [split [regsub -- {/Model.*$} $name ""] "/"] 0]
	set module [lindex [split [regsub -- {/Model.*$} $name ""] "/"] 1]
	set comment_text [create_comment $m_name $vendor $module]
	set module_namespace $vendor\\$module

	set module_dir [::system::config::get_magento_dir]/app/code/[regsub -- {/Model.*$} $name ""]

	set model_interface $module_dir/Api/Data/${model_template}Interface.php
	set model_class $module_dir/Model/$model_template.php
	set model_repository_interface $module_dir/Api/${model_template}RepositoryInterface.php
	set model_repository $module_dir/Model/${model_template}Repository.php
	set resource_model $module_dir/Model/ResourceModel/$model_template.php
	set model_collection $module_dir/Model/ResourceModel/$model_template/Collection.php
	
	foreach dir [split $name "/"] {
	    append created_name /$dir
	    if {[file exists $created_name] == 0} {
		exec mkdir $created_name
	    }
	}


	if {[file exists $module_dir/etc] == 0} {
	    exec mkdir $module_dir/etc
	}

	if {[file exists $module_dir/Api] == 0} {
	    exec mkdir $module_dir/Api
	    exec mkdir $module_dir/Api/Data
	}

	if {[file exists $module_dir/Model/ResourceModel] == 0} {
	    exec mkdir $module_dir/Model/ResourceModel
	    exec mkdir $module_dir/Model/ResourceModel/$model_template
	}

	# schema xml
	if {[file exists $module_dir/etc/db_schema.xml] == 0} {
	    set doc [dom createDocument schema]
	    set root [$doc documentElement]
	    set comment [$doc createComment $comment_text]
	    $doc insertBefore $comment $root
	    set schema [$root selectNodes {/schema}]
	    $schema setAttribute xsi::noNamespaceSchemaLocation "urn:magento:framework:Setup/Declaration/Schema/etc/schema.xsd"
	    set table_node [$doc createElement table]
	    $table_node setAttribute name $table resource "default" engine "innodb"
	    $root appendChild $table_node
	    set fp [open $module_dir/etc/db_schema.xml w]
	    puts $fp [$doc asXML -xmlDeclaration 1]
	    close $fp
	}

	set file_data [::system::utils::get_file_content $module_dir/etc/db_schema.xml]
	set doc [dom parse $file_data]
	set root [$doc documentElement]
	set node_name [append "" /schema/table "\[" @name=' $table "'\]" ]
	set node [$root selectNodes $node_name]

	if {[$node hasChildNodes] == 1} {
	    foreach children [$node childNodes] {
		$node removeChild $children
	    }
	}

	set item 0
	while {$item <= $field_no} {
	    if {$fields_list($item.name) != "" } {
		set field_node [$doc createElement column]
		$field_node setAttribute xsi:type "$fields_list($item.type)" name "$fields_list($item.name)" default "$fields_list($item.default)"

		if {$fields_list($item.type) == "int" || $fields_list($item.type) == "smallint"} {
		    $field_node setAttribute padding "$fields_list($item.size)"
		} else {
		    $field_node setAttribute length "$fields_list($item.size)"
		}

		if {$fields_list($item.null) == 0} {
		    $field_node setAttribute nullable "true"
		} else {
		    $field_node setAttribute nullable "false"		    
		}

		if {$item == 0} {
		    $field_node setAttribute identity "true"
		    set fields_list(identity) $fields_list($item.name)
		}
		
		$node appendChild $field_node
	    }
	    incr item
	}

	set fp [open $module_dir/etc/db_schema.xml w]
	puts $fp [$doc asXML -xmlDeclaration 1]
	close $fp

	# schema json
	if {[file exists $module_dir/etc/db_schema_whitelist.json] == 0} {
	    set fp [open $module_dir/etc/db_schema_whitelist.json w]
	    puts $fp "{}"
	    close $fp
	}

	set file_data [::system::utils::get_file_content $module_dir/etc/db_schema_whitelist.json]
	set doc [dom parse -json $file_data]
	set node [$doc selectNodes "//$table" ]
	if {$node != ""} {
	    $node delete
	}
	set table_node [$doc createElement $table]
	set column_node [$doc createElement "column"]
	set item 0
	while {$item <= $field_no} {
	    if {$fields_list($item.name) != ""} {
		set column [$doc createElement $fields_list($item.name)]
		$column appendChild [$doc createTextNode "true"]
		$column_node appendChild $column
	    }
	    incr item
	}
	$table_node appendChild $column_node
	$doc appendChild $table_node

	set fp [open $module_dir/etc/db_schema_whitelist.json w]
	puts $fp [$doc asJSON -indent 4]
	close $fp

	# Model Interface
	set fp [open $model_interface w]
	puts $fp "<?php$comment_text \nnamespace $vendor\\$module\\Api\\Data; \n\ninterface ${model_template}Interface \n\{"
	
	set item 0
	set const ""
	set body ""
	while {$item <= $field_no} {
	    set field_name $fields_list($item.name)
	    set camel_case [get_camel_case $field_name]

	    append const "\n" "\tconst [string toupper $field_name] = '$field_name';"
	    append body "\n" "\tpublic function get${camel_case}();\n\n\tpublic function set${camel_case}(\$$field_name);\n"
	    incr item
	}
	puts $fp $const
	puts $fp \n$body\}
	close $fp

	# model repository interface
	set fp [open $model_repository_interface w]
	set tpl_data [::system::utils::get_file_content $::load_path/etc/templates/model_repository_interface.tm2]
	eval "puts $fp \"${tpl_data}\""
	close $fp

	# model class
	set fp [open $model_class w]
	set tpl_data [::system::utils::get_file_content $::load_path/etc/templates/model_template.tm2]
	eval "puts $fp \"${tpl_data}\""

	set item 0
	while {$item <= $field_no} {
	    set field_name $fields_list($item.name)
	    set camel_case [get_camel_case $field_name]
	    puts $fp "\tpublic function get${camel_case}()\n\t\{\n\t\treturn \$this->getData(${model_template}Interface::[string toupper $field_name]);\n\t\}\n"
	    puts $fp "\tpublic function set${camel_case}(\$$field_name)\n\t\{\n\t\treturn \$this->setData(${model_template}Interface::[string toupper $field_name], \$$field_name);\n\t\}\n"
	    incr item
	}

	set camel_case [get_camel_case $fields_list(identity)]
	puts $fp "\tpublic function getIdentities()\n\t\{\n\t\treturn \['[string tolower ${vendor}_${module}_$model_template]_' . \$this->get${camel_case}()\];\n\t\}\n\}"
	close $fp

	# model repository
	set fp [open $model_repository w]
	set tpl_data [::system::utils::get_file_content $::load_path/etc/templates/model_repository.tm2]
	eval "puts $fp \"${tpl_data}\""
	close $fp

	# resource model
	set fp [open $resource_model w]
	set tpl_data [::system::utils::get_file_content $::load_path/etc/templates/resource_model.tm2]
	eval "puts $fp \"${tpl_data}\""
	close $fp

	# collection
	set fp [open $model_collection w]
	set tpl_data [::system::utils::get_file_content $::load_path/etc/templates/model_collection.tm2]
	eval "puts $fp \"${tpl_data}\""
	close $fp

	::system::windows::remove_progress
    }

    proc get_camel_case {var} {
	set result ""
	foreach word [split $var "_"] {
	    append result "" [string totitle $word]
	}
	return $result
    }
}
