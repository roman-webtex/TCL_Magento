#
# Magento 2 data config
#
global config

set config(catalog_product) 4
set config(catalog_product.main_table) {catalog_product_entity}
set config(catalog_product.main_table.id) {entity_id}
set config(catalog_product.attribute) {catalog_product_entity_$type}
set config(catalog_product.attribute_value) {value}
set config(catalog_product.attribute_store) {store_id}
set config(catalog_product.attribute_link) {$main_table.entity_id = $attribute_table.entity_id}
set cinfog(catalog_product.fields.category_ids) 

                    <item name="country_of_manufacture" xsi:type="string">catalog_product</item>
                    <item name="created_at" xsi:type="string">catalog_product</item>
                    <item name="custom_design" xsi:type="string">catalog_product</item>
                    <item name="custom_design_from" xsi:type="string">catalog_product</item>
                    <item name="custom_design_to" xsi:type="string">catalog_product</item>
                    <item name="custom_layout" xsi:type="string">catalog_product</item>
                    <item name="custom_layout_update" xsi:type="string">catalog_product</item>
                    <item name="description" xsi:type="string">catalog_product</item>
                    <item name="gallery" xsi:type="string">catalog_product</item>
                    <item name="has_options" xsi:type="string">catalog_product</item>
                    <item name="image" xsi:type="string">catalog_product</item>
                    <item name="image_label" xsi:type="string">catalog_product</item>
                    <item name="media_gallery" xsi:type="string">catalog_product</item>
                    <item name="meta_description" xsi:type="string">catalog_product</item>
                    <item name="meta_keyword" xsi:type="string">catalog_product</item>
                    <item name="meta_title" xsi:type="string">catalog_product</item>
                    <item name="minimal_price" xsi:type="string">catalog_product</item>
                    <item name="name" xsi:type="string">catalog_product</item>
                    <item name="news_from_date" xsi:type="string">catalog_product</item>
                    <item name="news_to_date" xsi:type="string">catalog_product</item>
                    <item name="old_id" xsi:type="string">catalog_product</item>
                    <item name="options_container" xsi:type="string">catalog_product</item>
                    <item name="page_layout" xsi:type="string">catalog_product</item>
                    <item name="price" xsi:type="string">catalog_product</item>
                    <item name="quantity_and_stock_status" xsi:type="string">catalog_product</item>
                    <item name="required_options" xsi:type="string">catalog_product</item>
                    <item name="short_description" xsi:type="string">catalog_product</item>
                    <item name="sku" xsi:type="string">catalog_product</item>
                    <item name="small_image" xsi:type="string">catalog_product</item>
                    <item name="small_image_label" xsi:type="string">catalog_product</item>
                    <item name="special_from_date" xsi:type="string">catalog_product</item>
                    <item name="special_price" xsi:type="string">catalog_product</item>
                    <item name="special_to_date" xsi:type="string">catalog_product</item>
                    <item name="status" xsi:type="string">catalog_product</item>
                    <item name="thumbnail" xsi:type="string">catalog_product</item>
                    <item name="thumbnail_label" xsi:type="string">catalog_product</item>
                    <item name="tier_price" xsi:type="string">catalog_product</item>
                    <item name="updated_at" xsi:type="string">catalog_product</item>
                    <item name="visibility" xsi:type="string">catalog_product</item>
                    <item name="weight" xsi:type="string">catalog_product</item>
