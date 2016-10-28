/**
* @author Roy Lou
* @date 10/10/2016 
*
* @obsolete
*
* @group Network Quote
* @group-content ../../ApexDocContent/OCD_IDNAddMembersBatchable.htm 
*
* @description Add member quotes to an IDN quote
* @Change History
*
*   Tag         Author              Date             Requested-BY      Description     
* *****************************************************************************************************************              
*   1.0.0      Roy Lou        10/10/2016        N/A               Initial Version                            
* *****************************************************************************************************************/

public class OCD_ModelPPController {
	/*********************************************************************************************
    * @description class variables
    **********************************************************************************************/
    public class OptionItem {
    	public OptionItem() {
    		optionsGroups = new set<String>();	
    	}
    	public String SKU { get; set; }
    	public String optionName { get; set; }
    	public String productType { get; set; }
    	public set<String> optionsGroups { get; set; }
    	public String optionGroupList { get; set; }
    }
    public List<SelectOption> modelOptionList {get;set;}
    public List<SelectOption> priceOptionList {get;set;}
    public List<String> selectedModelId {get;set;}
    public List<String> selectedPriceId {get;set;}
    
    public List<REVVY__MnPriceList__c> priceList {get;set;}
    public List<REVVY__MnConfigEngineModel__c> modelList {get;set;}
    public List<OCD_ModelPPController.OptionItem> optionList {get; set; }
	public List<ModelPPSKU> missingSKUinModelList {get;set;}
	public List<ModelPPSKU> missingSKUinPPList {get;set;}
    /*********************************************************************************************
    * @description Constructor
    **********************************************************************************************/	
	public OCD_ModelPPController() {
		
	}    
    /*********************************************************************************************
    * @description Compare model
    * @return void
    **********************************************************************************************/
	public void executeCompare() {
		compareModel();
	}
    /*********************************************************************************************
    * @description Compare models and price lists
    * @return void
    **********************************************************************************************/
	public void compareModel() {
		system.debug('selectedModelId=' + selectedModelId);
		//Sku in Model but not Price Plan
		list<REVVY__MnConfigEngineModel__c> models = [SELECT Id, Name, REVVY__Compile_Date__c, REVVY__Compiled_Model_Attachment_Id__c
		                                                   , REVVY__Compiled_Version__c, REVVY__Id__c, REVVY__IsSolution__c, REVVY__ModelLocale__c
		                                                   , REVVY__Model_definition_id__c, REVVY__Product_IDs__c, REVVY__Status__c, REVVY__User_id__c
		                                                   , REVVY__AttrIDs__c, REVVY__ExportedModelAttachmentId__c 
		                                                FROM REVVY__MnConfigEngineModel__c 
		                                               where Id in :selectedModelId
		                                                 and REVVY__Status__c <> 'Draft'];

		Set<String> pSet = new Set<String>();
		for(REVVY__MnConfigEngineModel__c m : models) {
			String productsInModel = m.REVVY__Product_IDs__c;
			productsInModel = productsInModel.remove('[').remove(']').remove('"');
			string[] productArray = productsInModel.split(',');
			pSet.addAll(new set<String>(productArray));
			system.debug('size of pSet = ' + pSet.size() );
		}

		Map<String,String> pMap = new Map<String,String>();
		for(REVVY__MnCatalogNode__c cn:[Select Id, Name, Revvy__Id__c From REVVY__MnCatalogNode__c where Revvy__Id__c in :pSet]) {
			pMap.put(cn.Revvy__Id__c,cn.Name);
		}
		
		//Sku in Price Plan but not Model
		
		Set<String> ppSKUSet = new Set<String>();
		missingSKUinModelList = new List<ModelPPSKU>();
		for(REVVY__MnPriceListLine__c pll:[Select Id, Revvy__Id__c, Revvy__Product_Name__c, REVVY__Product__r.REVVY__Id__c  From REVVY__MnPriceListLine__c 
		                                    where REVVY__PriceList__c in :selectedPriceId]) {
			ppSKUSet.add(pll.REVVY__Product__r.REVVY__Id__c);	 
			if(!pSet.contains(pll.Revvy__Id__c)) {
				ModelPPSKU msku = new ModelPPSKU();
				msku.sku = pll.REVVY__Product__r.REVVY__Id__c;
				msku.productName = pll.Revvy__Product_Name__c;
				missingSKUinModelList.add(msku);
			}                                     	
		}
		missingSKUinPPList = new List<ModelPPSKU>();
		for(String modelSKU:pMap.keySet()) {
			if(!ppSKUSet.contains(modelSKU)) {
				ModelPPSKU msku = new ModelPPSKU();
				msku.sku = modelSKU;
				msku.productName = pMap.get(modelSKU);
				missingSKUinPPList.add(msku);
			}
		}
		system.debug('------------' + pSet);
		system.debug('------------' + ppSKUSet);
		Set<String> includedSkuSet = new Set<String>();
		for(String s : pSet) {
			if(ppSKUSet.contains(s)) {
				includedSkuSet.add(s);	
			}
		}
		system.debug('------------includedSkuSet = ' + includedSkuSet);
		List<REVVY__MnConfigEngineOption__c> options = [Select REVVY__Option_Group__r.revvy__Id__c, REVVY__Label__c, 
											REVVY__Catalog_Node__r.product_type__c, REVVY__Catalog_Node__r.revvy__Id__c, Id From REVVY__MnConfigEngineOption__c 
											where REVVY__Catalog_Node__r.revvy__Id__c in :includedSkuSet and REVVY__Option_Group__c in 
											(select REVVY__OptionGroup_Id__c from REVVY__MnConfigEngineModelOptionGroupJunction__c where 
											REVVY__Model_Id__c = :selectedModelId)];
		system.debug('-----------' + options);									
		Map<String, OCD_ModelPPController.OptionItem> sku2OptionMap = new Map<String, OCD_ModelPPController.OptionItem>();
		for(REVVY__MnConfigEngineOption__c option : options) {
			if(!sku2OptionMap.containsKey(option.REVVY__Catalog_Node__r.revvy__Id__c))	{
				sku2OptionMap.put(option.REVVY__Catalog_Node__r.revvy__Id__c, new OCD_ModelPPController.OptionItem());		
			}
			OCD_ModelPPController.OptionItem optionItem = sku2OptionMap.get(option.REVVY__Catalog_Node__r.revvy__Id__c);
			optionItem.SKU = option.REVVY__Catalog_Node__r.revvy__Id__c;
			optionItem.optionName = option.REVVY__Label__c;
			optionItem.productType = option.REVVY__Catalog_Node__r.product_type__c;
			optionItem.optionsGroups.add(option.REVVY__Option_Group__r.revvy__Id__c);
		}
		optionList = (List<OCD_ModelPPController.OptionItem>)sku2OptionMap.values();
		for(OCD_ModelPPController.OptionItem oi : optionList) {
			oi.optionGroupList = String.join(new List<String>(oi.optionsGroups), ',');
		}
	}    

    /*********************************************************************************************
    * @description Initialize select lists of models and price lists
    * @return void
    **********************************************************************************************/
	public void init() {
		missingSKUinPPList = new List<ModelPPSKU>();
		missingSKUinModelList = new List<ModelPPSKU>();
		modelOptionList = new List<SelectOption>();
		modelList = [SELECT Id, Name, REVVY__Compile_Date__c, REVVY__Compiled_Model_Attachment_Id__c
                           , REVVY__Compiled_Version__c, REVVY__Id__c, REVVY__IsSolution__c, REVVY__ModelLocale__c
                           , REVVY__Model_definition_id__c, REVVY__Product_IDs__c, REVVY__Status__c, REVVY__User_id__c
                           , REVVY__AttrIDs__c, REVVY__ExportedModelAttachmentId__c 
                        FROM REVVY__MnConfigEngineModel__c where REVVY__Status__c <> 'Draft' Order by Name];
		if(modelList!=null && modelList.size()>0) {
			for(REVVY__MnConfigEngineModel__c em:modelList) {
				modelOptionList.add(new SelectOption(em.Id,em.Name));
			}
		}
		
		priceOptionList = new List<SelectOption>();
		priceList = [Select Id, Name, Is_Valid__c From REVVY__MnPriceList__c where Is_Valid__c = true Order by Name];
		for(REVVY__MnPriceList__c pl: priceList) {
			priceOptionList.add(new SelectOption(pl.Id,pl.Name));
		} 
	}
	public class ModelPPSKU {
		public String sku {get;set;}
		public String productName {get;set;}
	}
}