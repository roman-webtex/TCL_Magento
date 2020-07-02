/home/roman/work/docker/ricambi_m2/compose/src/app/code/Magenmagic/Ricambi/Model/Catalog/Category.php
<?php
/**
 * @category Magenmagic_Ricambi_Category
 * @author MagenMagic Team
 * @copyright Copyright (c) 2020 MagenMagic (https://www.magenmagic.com)
 * @package Magenmagic_Ricambi
 */

namespace Magenmagic\Ricambi\Model\Catalog;

class Category extends \Magento\Catalog\Model\Category {

    const PART_DIAGRAM_CATEGORY_ID          = 3;
    const COLLECTIONS_CATEGORY_ID           = 4;

    const CATEGORY_DIAGRAM_VIEW_MODE_LIST   = 'list';
    const CATEGORY_DIAGRAM_VIEW_MODE_SPLIT  = 'split';

    /**
     * Retrieve categories by parent
     *
     * @param int $parent
     * @param int $recursionLevel
     * @param bool $sorted
     * @param bool $asCollection
     * @param bool $toLoad
     * @return mixed
     */
    public function getCategories($parent, $recursionLevel = 0, $sorted=false, $asCollection=false, $toLoad=true, $carDiagrams=false)
    {
        $categories = $this->getResource()->getCategories($parent, $recursionLevel, $sorted, $asCollection, $toLoad ,$carDiagrams);
        return $categories;
    }

    /**
     * Get filter value for reset current filter state
     *
     * @return mixed
     */
    public function getResetValue()
    {
        if ($this->_appliedCategory) {
            /**
             * Revert path ids
             */
            $pathIds = array_reverse($this->_appliedCategory->getPathIds());
            $curCategoryId = $this->getLayer()->getCurrentCategory()->getId();
            if (isset($pathIds[1]) && $pathIds[1] != $curCategoryId && self::COLLECTIONS_CATEGORY_ID != $pathIds[1]) {
                return $pathIds[1];
            }
        }
        return null;
    }

    // is this category a child of Car Diagrams?
    public function isCarDiagramCategory()
    {
        return in_array(self::PART_DIAGRAM_CATEGORY_ID, $this->getPathIds());
    }

    // is this category a diagram (as opposed to a category containing diagrams)?
    public function isCarDiagram()
    {
        return ($this->isCarDiagramCategory() && $this->getOscCatalogPage()); //Where did this go?
    }

    //This returns the current category or its parent if this is a part diagram
    public function getPartDiagramCategoryId()
    {
        $partDiagramCategoryId = null;
        if($this->isCarDiagram()) {
            $partDiagramCategoryId = $this->getParentId();
        } elseif ($this->isCarDiagramCategory()) {
            $partDiagramCategoryId = $this->getId();
        }
        return $partDiagramCategoryId;
    }

    public function getSplitViewUrl()
    {
        return $this->getUrl() . '?mode=' . self::CATEGORY_DIAGRAM_VIEW_MODE_SPLIT;
    }
}
