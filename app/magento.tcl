# Tcl/Tk Magento Helper                
# Distrubuted under GPL               
# Copyright (c) "Roman Dmytrenko", 2020       
# Author: Roman Dmytrenko roman.webtex@gmail.com 
#
# magento common command

namespace eval system::magento {

    variable di_fields_type
    global project

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

    proc get_index_name {field_no} {
        global fields_list

        if {$fields_list($field_no.index) == "" } {
            return
        } elseif {$fields_list($field_no.index) == "PRIMARY"} {
            set index_name "PRIMARY"
        } else {
            set index_name "INDEX_"
        }

        dict set table_index index-name $index_name
        set param [::system::windows::get_params_window $table_index]
        set fields_list($field_no.index_name) [dict get $table_index index-name]
    }

    proc get_module_dir_by_class_name { class_name } {
        set class_file [get_file_by_class_name $class_name]
        return [regsub -- {/Model.*$} $class_file "/"]
    }

    proc get_module_name_from_registration { registration_file_name } {
        if {$registration_file_name == ""} {
            return ""
        }
        set file_data [::system::utils::get_file_content $registration_file_name]
        regsub -all {/\*.*?\*/} $file_data {} file_data
        return [string trim [lindex [split $file_data ","] 1] " '\""]
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

        set psr4data [::system::utils::get_file_content $psr4config]

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

    proc open_module_from_menu {} {
        global project
        if {[set file_name [::system::utils::open_file "Select module registration.php" [::system::config::get_magento_dir] "registration.php" ]] != ""} {
            set module_name [get_module_name_from_registration $file_name]
            if {[array get project magento_path] == ""} {
                set project(magento_path) [::system::config::get_magento_dir]
            }
            set project(module.$module_name) $module_name
            set project(active) $module_name
            .root.status.lab configure -text "[ mc "Magento root set to " ][ ::system::config::get_magento_dir ];  Active module are $module_name"
        }
    }

    proc get_entity_id {{type product}} {
        variable $type
        set sql "select entity_type_id from eav_entity_type"
    }

    proc mysql {} {
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
        
        if {$file_data == "" || $file_data == false} {
            return result            
        }

        set doc [dom parse $file_data]
        set root [$doc documentElement]
        set node [$root selectNodes {/config/type/arguments/argument[@name='typeFactories']}]
        set child_nodes [$node selectNodes item]

        foreach item $child_nodes {
            lappend result [lindex [split [lindex [$item selectNodes attribute::name] 0] " "] 1]
        }

        return $result
    }

    proc get_fields_attribute {} {
        return [list {} BINARY UNSIGNED {UNSIGNED ZEROFILL} {on update CURRENT_TIMESTAMP}]
    }

    proc get_fields_index {} {
        return [list {} PRIMARY UNIQUE INDEX FULLTEXT SPATIAL]
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
        }

        if {[file exists $module_dir/Model/ResourceModel/$model_template] == 0} {
            exec mkdir $module_dir/Model/ResourceModel/$model_template            
        }

        # schema xml
        if {[file exists $module_dir/etc/db_schema.xml] == 0} {
            set doc [dom createDocument schema]
            set root [$doc documentElement]
            set comment [$doc createComment $comment_text]
            $doc insertBefore $comment $root
            set schema [$root selectNodes {/schema}]
            $schema setAttribute xmlns:xsi "http://www.w3.org/2001/XMLSchema-instance" xsi:noNamespaceSchemaLocation "urn:magento:framework:Setup/Declaration/Schema/etc/schema.xsd"
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

        if {$node == ""} {
            set table_node [$doc createElement table]
            $table_node setAttribute name $table resource "default" engine "innodb"
            $root appendChild $table_node
            set node [$root selectNodes $node_name]
        }

        if {[$node hasChildNodes] == 1} {
            foreach children [$node childNodes] {
                $node removeChild $children
            }
        }

        set item 0
        while {$item <= $field_no} {
            if {$fields_list($item.name) != "" } {
                set field_node [$doc createElement column]
                set definition [create_definition $item]

                dict for {key value} $definition {
                    if {$value != ""} {
                        $field_node setAttribute $key "$value"
                    }
                }
                
                $node appendChild $field_node
            }
            incr item
        }
        set index_node [$doc createElement constraint]
        $index_node setAttribute xsi:type "primary" referenceId $fields_list(index.primary)
        $node appendChild $index_node
        set index_column [$doc createElement column]
        $index_column setAttribute name $fields_list(identity)
        $index_node appendChild $index_column
        

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

        if {$fields_list(identity) != ""} {
            set index_node [$doc createElement "constraint"]
            set index [$doc createElement $fields_list(index.primary)]
            $index appendChild [$doc createTextNode "true"]
            $index_node appendChild $index
            $table_node appendChild $index_node
        }

        $doc appendChild $table_node

        set fp [open $module_dir/etc/db_schema_whitelist.json w]
        puts $fp [$doc asJSON -indent 4]
        close $fp

        # di.xml
        if {[file exists $module_dir/etc/di.xml] == 0} {
            set doc [dom createDocument config]
            set root [$doc documentElement]
            set comment [$doc createComment $comment_text]
            $doc insertBefore $comment $root
            set config [$root selectNodes {/config}]
            $config setAttribute xmlns:xsi "http://www.w3.org/2001/XMLSchema-instance" xsi:noNamespaceSchemaLocation "urn:magento:framework:ObjectManager/etc/config.xsd"
            set fp [open $module_dir/etc/di.xml w]
            puts $fp [$doc asXML -xmlDeclaration 1]
            close $fp
        }

        set file_data [::system::utils::get_file_content $module_dir/etc/di.xml]
        set doc [dom parse $file_data]
        set root [$doc documentElement]
        set node [$root selectNodes {/config}]

        # preferences
        set preference [$doc createElement preference]
        $preference setAttribute for "$vendor\\$module\\Api\\Data\\${model_template}Interface" type "$vendor\\$module\\Model\\${model_template}"
        $node appendChild $preference
        set preference [$doc createElement preference]
        $preference setAttribute for "$vendor\\$module\\Api\\${model_template}RepositoryInterface" type "$vendor\\$module\\Model\\${model_template}Repository"
        $node appendChild $preference

        # repository factory
        set node_name [append "" /config/type \[@name='Magento\\Framework\\Model\\Entity\\RepositoryFactory'\] ]
        set repository_factory [$root selectNodes $node_name]

        if {$repository_factory == ""} {
            set repository_factory [$doc createElement type]
            $repository_factory setAttribute name "Magento\\Framework\\Model\\Entity\\RepositoryFactory"
            set arguments [$doc createElement arguments]
            set argument [$doc createElement argument]
            $argument setAttribute name "entities" xsi:type "array"
            $arguments appendChild $argument
            $repository_factory appendChild $arguments
            $node appendChild $repository_factory
        }

        # repository factory item
        set item_name [append "" /arguments/argument/item \[@name='$vendor\\$module\\Api\\Data\\${model_template}Interface'\]]
        set item [$repository_factory selectNodes $item_name]

        if {$item == ""} {
            set item [$doc createElement item]
            $item setAttribute name "$vendor\\$module\\Api\\Data\\${model_template}Interface" xsi:type "string"
            $item appendChild [$doc createTextNode "$vendor\\$module\\Api\\${model_template}RepositoryInterface"]
            $argument appendChild $item
        }

        # metadata pool
        set node_name [append "" /config/type \[@name='Magento\\Framework\\EntityManager\\MetadataPool'\] ]
        set metadata_pool [$root selectNodes $node_name]

        if {$metadata_pool == ""} {
            set metadata_pool [$doc createElement type]
            $metadata_pool setAttribute name "Magento\\Framework\\EntityManager\\MetadataPool"
            set arguments [$doc createElement arguments]
            set argument [$doc createElement argument]
            $argument setAttribute name "metadata" xsi:type "array"
            $arguments appendChild $argument
            $metadata_pool appendChild $arguments
            $node appendChild $metadata_pool
        }

        # metadata pool item
        set item_name [append "" /arguments/argument/item \[@name='$vendor\\$module\\Api\\Data\\${model_template}Interface'\]]
        set item [$metadata_pool selectNodes $item_name]

        if {$item == ""} {
            set item [$doc createElement item]
            $item setAttribute name "$vendor\\$module\\Api\\Data\\${model_template}Interface" xsi:type "array"
            set entity_table_name [$doc createElement item]
            $entity_table_name setAttribute name "entityTableName" xsi:type "string"
            $entity_table_name appendChild [$doc createTextNode $table]
            set identifier_field [$doc createElement item]
            $identifier_field setAttribute name "identifierField" xsi:type "string"
            $identifier_field appendChild [$doc createTextNode $fields_list(identity)]
            $item appendChild $entity_table_name
            $item appendChild $identifier_field
            $argument appendChild $item
        }
        
        set fp [open $module_dir/etc/di.xml w]
        puts $fp [$doc asXML -xmlDeclaration 1]
        close $fp

        # Model Interface
        set fp [open $model_interface w]
        puts $fp "<?php$comment_text \nnamespace $vendor\\$module\\Api\\Data; \n\ninterface ${model_template}Interface \n\{"
        
        set item 0
        set const ""
        set body ""
        while {$item <= $field_no} {
            set field_name $fields_list($item.name)
            if {$field_name != ""} {
                set camel_case [get_camel_case $field_name]
                append const "\n" "\tconst [string toupper $field_name] = '$field_name';"
                append body "\n" "\t/**\n\t * @return $fields_list($item.type)\n\t */\n\tpublic function get${camel_case}();\n\n\t/**\n\t * @param \$$field_name\n\t * return ${model_template}Interface\n\t */\n\tpublic function set${camel_case}(\$$field_name);\n"
            }
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
            if {$field_name != ""} {
                set camel_case [get_camel_case $field_name]
                puts $fp "\tpublic function get${camel_case}()\n\t\{\n\t\treturn \$this->getData(${model_template}Interface::[string toupper $field_name]);\n\t\}\n"
                puts $fp "\tpublic function set${camel_case}(\$$field_name)\n\t\{\n\t\treturn \$this->setData(${model_template}Interface::[string toupper $field_name], \$$field_name);\n\t\}\n"
            }
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

        tk_messageBox -title "Ready" -message "Model '$m_name' was successfully created." -type ok
    }

    proc create_definition {line_no} {
        global fields_list

        array set fields_length { tinyint 3 smallint 6 mediumint 8 int 11 bigint 20 float {0,0} decimal {10,0} double {0,0} varchar 255 }
        set type $fields_list($line_no.type)

        if {[string tolower $type] == "integer"} {
            set type "int"
        }

        set size $fields_list($line_no.size)
        if {$size == ""} {
            set size [lindex [split [array get fields_length $type] " "] 1]
        }
        
        dict set column_definition xsi:type $type
        dict set column_definition name $fields_list($line_no.name)

        if {$fields_list($line_no.attribute) == "UNSIGNED"} {
            if {$type == "tinyint"} {
                dict set column_definition unsigned "true"                
            }
            if {$type == "int" || $type == "smallint"} {
                dict set column_definition unsigned "true"
                incr size -1
            }
        } else {
            if {$type == "tinyint" || $type == "int" || $type == "smallint"} {
                dict set column_definition unsigned "false"
            }
        }

        if {$fields_list($line_no.attribute) == "on update CURRENT_TIMESTAMP" && $type == "timestamp"} {
            dict set column_definition on_update "true"
            dict set column_definition default "CURRENT_TIMESTAMP"
        } elseif {$type == "timestamp"} {
            dict set column_definition on_update "false"
            dict set column_definition default "CURRENT_TIMESTAMP"
        } else {
            dict set column_definition default $fields_list($line_no.default)
        }
        
        if {$type == "float" || $type == "decimal" || $type == "double"} {
            dict set column_definition precision [lindex [split $size ,] 0]
            dict set column_definition scale [lindex [split $size ,] 1]
        } elseif {[string match {int} $type] == 1} {
            dict set column_definition padding $size
        } else {
            dict set column_definition length $size
        }

        if {$fields_list($line_no.ai) == 1} {
            dict set column_definition nullable "false"
            dict set column_definition identity "true"
            set fields_list(identity) $fields_list($line_no.name)
            set fields_list(index.primary) $fields_list($line_no.index_name) 
        } else {
            if {$type == "tinyint" || $type == "int" || $type == "smallint"} {
                dict set column_definition identity "false"
            }
        }

        return [dict get $column_definition]
    }

    proc create_module {model_name {version "0.0.1"}} {
        global fields_list
        global module_depends
        global project

        ::system::windows::add_progress
        
        set name [regsub -all -- _ $model_name /]
        set created_name [::system::config::get_magento_dir]/app/code
        set vendor [lindex [split [regsub -- {/Model.*$} $name ""] "/"] 0]
        set module [lindex [split [regsub -- {/Model.*$} $name ""] "/"] 1]
        set comment_text [create_comment $model_name $vendor $module]

        set module_dir [::system::config::get_magento_dir]/app/code/[regsub -- {/Model.*$} $name ""]

        if {[file exists $created_name/$vendor] == 0} {
            exec mkdir $created_name/$vendor
        }
        
        if {[file exists $created_name/$vendor/$module] == 0} {
            exec mkdir $created_name/$vendor/$module
        }

        if {[file exists $module_dir/etc] == 0} {
            exec mkdir $module_dir/etc
        }

        if {[file exists $module_dir/Helper] == 0} {
            exec mkdir $module_dir/Helper
            set fp [open $module_dir/Helper/Data.php w]
            set tpl_data [::system::utils::get_file_content $::load_path/etc/templates/helper_data.tm2]
            eval "puts $fp \"${tpl_data}\""
            close $fp
        }
        
        set doc [dom createDocument config]
        set root [$doc documentElement]
        set comment [$doc createComment $comment_text]
        $doc insertBefore $comment $root
        set config_node [$root selectNodes {/config}]
        $config_node setAttribute xmlns:xsi "http://www.w3.org/2001/XMLSchema-instance" xsi:noNamespaceSchemaLocation "urn:magento:framework:Module/etc/module.xsd"
        set module_node [$doc createElement {module}]
        $module_node setAttribute name "${vendor}_${module}" setup_version $version
        set sequence_node [$doc createElement {sequence}]
        if {[array exists module_depends] == 1} {
            foreach {name value} [array get module_depends] {
                puts $value
                if {$value != ""} {
                    set sequence_model [$doc createElement {model}]
                    $sequence_model setAttribute name $value
                    $sequence_node appendChild $sequence_model
                }
            }
        }
        $module_node appendChild $sequence_node
        $config_node appendChild $module_node
        set fp [open $module_dir/etc/module.xml w]
        puts $fp [$doc asXML -xmlDeclaration 1]
        close $fp

        # registration
        set fp [open $module_dir/registration.php w]
        set tpl_data [::system::utils::get_file_content $::load_path/etc/templates/registration.tm2]
        eval "puts $fp \"${tpl_data}\""
        close $fp

        if {[array get project magento_path] == ""} {
            set project(magento_path) [::system::config::get_magento_dir]
        }
        
        set project(module.${vendor}_${module}) ${vendor}_${module}
        set project(active) ${vendor}_${module}
        .root.status.lab configure -text "[ mc "Magento root set to " ][ ::system::config::get_magento_dir ];  Active module are ${vendor}_${module}"

        ::system::windows::remove_progress
    }

    proc add_admin_gridview_model {} {
        ::system::windows::add_progress

        ::system::windows::admin_gridview_model_window
        
        ::system::windows::remove_progress
    }

    proc get_camel_case {var} {
        set result ""
        foreach word [split $var "_"] {
            append result "" [string totitle $word]
        }
        return $result
    }

    proc set_active_module {module_name} {
        global project
        set project(active) $module_name
        .root.status.lab configure -text "[ mc "Magento root set to " ][ ::system::config::get_magento_dir ];  Active module are $module_name"
    }
}
