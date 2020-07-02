# magento common command

namespace eval system::magento {

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
	dict set model name ""
	dict set model fieldset {}
	set result [::system::windows::get_model_window]
	puts $result
    }
}
