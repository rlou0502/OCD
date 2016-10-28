public class MyTools {
	public static String test(String mName) {
		//Model_boxyg	
		Revvy__MnConfigEngineModel__c modl = [select id, Revvy__Compiled_Model_Attachment_Id__c 
							from Revvy__MnConfigEngineModel__c where id = 'a3J290000004XKy'];
		String jsonModel  = getJSON(modl);
		system.debug(modl.Revvy__Compiled_Model_Attachment_Id__c);
		//system.debug(jsonModel);
		jsonModel = getLocaleSpecificJsonModel(jsonModel);
		//system.debug(jsonModel);
		return jsonModel;
	}
	//Model_boxyg
	public static String test3(String mName, String countryCode, String majorLOB) {
		return OCD_ProductExclusionPlugin.getExclusiveProductCategoryFromModel(mName, countryCode, majorLOB);
	}
	public static String test2(String mName) {
		//Model_boxyg	
		Revvy__MnConfigEngineModel__c modl = [select id, Revvy__Compiled_Model_Attachment_Id__c 
							from Revvy__MnConfigEngineModel__c where id = 'a3J290000004XKy'];
		String jsonModel  = getJSON(modl);
		system.debug(modl.Revvy__Compiled_Model_Attachment_Id__c);
		
		set<String> m = 
			getCatalogNodeFromOptions(
				(Map<String, Object>) JSON.deserializeUntyped(jsonModel));
				
				
		return JSON.serialize(m);
	}
	public static String getJSON(Revvy__MnConfigEngineModel__c m) {
		if(m == null || m.Revvy__Compiled_Model_Attachment_Id__c == null) {
			return null;
		}

		Attachment[] a = [SELECT Id, Body FROM Attachment
						WHERE Id = :m.Revvy__Compiled_Model_Attachment_Id__c];

		if(a.size() == 0) {
			return null;
		} else {
			return a.get(0).Body.toString();
		}
	}
	
	public static String getLocaleSpecificJsonModel(String jsonModel) {
		Map<String, Object> m =
			getLocaleSpecificJsonModelMap(
				(Map<String, Object>) JSON.deserializeUntyped(jsonModel));
		return JSON.serialize(m);
	}
	
	public static Map<String, Object> getLocaleSpecificJsonModelMap(Map<String, Object> jsonMap) {
		Map<String, Object> optionGroups = (Map<String, Object>)jsonMap.get(MODEL_ATTR_GROUPS);
		if (optionGroups == null) {
			return jsonMap;
		}
		Set<String> uidOptionGroup = new Set<String>();
		Set<String> nodeIdForCategoryAsOption = new Set<String>();
		Set<String> uidForRegularAsOption = new Set<String>();
		Set<String> attrIdForPredefinedType = new Set<String>();

		for(String grpId: optionGroups.keyset()) {
			Map<String, Object> groupObj = (Map<String, Object>) optionGroups.get(grpId);
			system.debug('option group -->' + (String)groupObj.get(MODEL_ATTR_U_ID));
			uidOptionGroup.add((String)groupObj.get(MODEL_ATTR_U_ID));
			List<Object> options = (List<Object>) groupObj.get(MODEL_ATTR_OPTIONS);
			for(Object temp : options){
				Map<String, Object> option = (Map<String, Object>) temp;
				if(groupObj.get('type') == 'category') {
					nodeIdForCategoryAsOption.add((String)option.get(MODEL_ATTR_IDNODE));
				}
				if(groupObj.get('type') == 'regular') {
					system.debug('option  -->' + (String)option.get(MODEL_ATTR_U_ID));
					uidForRegularAsOption.add((String)option.get(MODEL_ATTR_U_ID));
				}
			}

			List<Object> userEnteredAttrList = (List<Object>) groupObj.get(MODEL_USER_ENTERED_ATTRS);
			if(userEnteredAttrList != null && userEnteredAttrList.size() > 0) {
				for(Object obj :userEnteredAttrList) {
					Map<String, Object> userEnteredAttr = (Map<String, Object>) obj;
						attrIdForPredefinedType.add((String)userEnteredAttr.get(MODEL_USER_ENTERED_ATTR_ID));
				}
			}
		}

		// Now we got All the Ids that we needed to populate the Maps
		// SQOL to get the LocaleName or/and LocaleDescription
		Map<String, List<String>> uidOGToLocaleNameAndDescription = new Map<String, List<String>>();
		List<Revvy__MnConfigEngineOptionGroup__c> ogList = [select Revvy__Id__c, Revvy__LocaleName_F__c,Revvy__LocaleDesc_F__c from Revvy__MnConfigEngineOptionGroup__c where Revvy__id__c in :uidOptionGroup];
		for(Revvy__MnConfigEngineOptionGroup__c og: ogList) {
			uidOGToLocaleNameAndDescription.put(og.Revvy__Id__c, new List<String>{og.Revvy__LocaleName_F__c,og.Revvy__LocaleDesc_F__c});
		}

		Map<String, String> nodeIdForCategoryAsOptionToLocaleName = new Map<String, String>();
		List<Revvy__MnCatalogNode__c> catNodes = [Select Revvy__id__c, Revvy__LocaleName_F__c from Revvy__MnCatalogNode__c where Revvy__id__c IN :nodeIdForCategoryAsOption];
		for(Revvy__MnCatalogNode__c catNode: catNodes){
			nodeIdForCategoryAsOptionToLocaleName.put(catNode.Revvy__Id__c, catNode.Revvy__LocaleName_F__c);
		}

		Map<String, String> uidForRegularAsOptionToLocaleName = new Map<String, String>();
		List<Revvy__MnConfigEngineOption__c> optionList = [select Revvy__id__c, Revvy__LocaleName_F__c from Revvy__MnConfigEngineOption__c where Revvy__id__c IN :uidForRegularAsOption];

		for(Revvy__MnConfigEngineOption__c regularOption: optionList){
			system.debug(regularOption.Revvy__Id__c + '----'  + regularOption.Revvy__LocaleName_F__c);
			uidForRegularAsOptionToLocaleName.put(regularOption.Revvy__Id__c, regularOption.Revvy__LocaleName_F__c);
		}

		Map<String, Map<String, String>> attrIdToLocaleName = new Map<String, Map<String, String>>();
		Map<String, String> attIdToLocaleAttributeName = new Map<String, String>();

		List<Revvy__MnCatalogAttributeValue__c> attributeValues = [Select Revvy__Value_Display__c,Revvy__Catalog_Attribute__r.Revvy__Id__c,Revvy__LocaleDName_F__c,Revvy__Catalog_Attribute__r.Revvy__LocaleName_F__c FROM Revvy__MnCatalogAttributeValue__c where Revvy__Catalog_Attribute__r.Revvy__Id__c IN :attrIdForPredefinedType];

		for(Revvy__MnCatalogAttributeValue__c attrVal: attributeValues){
			attrIdToLocaleName.put(attrVal.Revvy__Catalog_Attribute__r.Revvy__Id__c, createDisplayNameToLocaleName(attributeValues));
			attIdToLocaleAttributeName.put(attrVal.Revvy__Catalog_Attribute__r.Revvy__Id__c,attrVal.Revvy__Catalog_Attribute__r.Revvy__LocaleName_F__c );
		}

		Map<String, String> attIdToLocaleUserEnteredAttributeName = new Map<String, String>();
		List<Revvy__MnCatalogAttribute__c> userEnteredattributeNames = [Select Revvy__Id__c,Revvy__LocaleName_F__c FROM Revvy__MnCatalogAttribute__c where Revvy__Id__c IN :attrIdForPredefinedType];

		for(Revvy__MnCatalogAttribute__c ueAttrName: userEnteredattributeNames){
			attIdToLocaleUserEnteredAttributeName.put(ueAttrName.Revvy__Id__c,ueAttrName.Revvy__LocaleName_F__c );
		}

		//Loop 2nd time to replace the Name and Description field
		for(String grpId: optionGroups.keyset()) {
			Map<String, Object> groupObj = (Map<String, Object>) optionGroups.get(grpId);
			if(uidOGToLocaleNameAndDescription.isEmpty() == false) {
				groupObj.put('label', (uidOGToLocaleNameAndDescription.get((String)groupObj.get(MODEL_ATTR_U_ID))).get(0));
				groupObj.put('description', (uidOGToLocaleNameAndDescription.get((String)groupObj.get(MODEL_ATTR_U_ID))).get(1));
			}
			system.debug('---------------------------------------');
			List<Object> options = (List<Object>) groupObj.get(MODEL_ATTR_OPTIONS);
			for(Object temp : options) {
				Map<String, Object> option = (Map<String, Object>) temp;
				system.debug('---------------'+ option.get(MODEL_ATTR_U_ID) + ' ---- ' + option.get(MODEL_ATTR_UID));
				if(groupObj.get('type') == 'category' && nodeIdForCategoryAsOptionToLocaleName.isEmpty() == false) {
					option.put('label', nodeIdForCategoryAsOptionToLocaleName.get((String)option.get(MODEL_ATTR_IDNODE)));
				}
				if(groupObj.get('type') == 'regular' && uidForRegularAsOptionToLocaleName.isEmpty() == false) {
					option.put('name', uidForRegularAsOptionToLocaleName.get((String)option.get(MODEL_ATTR_U_ID)));
					option.put('label', uidForRegularAsOptionToLocaleName.get((String)option.get(MODEL_ATTR_U_ID)));
					system.debug(option.get('name') + '----'  + option.get('label'));
				}
			}

			List<Object> userEnteredAttrList = (List<Object>) groupObj.get(MODEL_USER_ENTERED_ATTRS);
			if(userEnteredAttrList != null && userEnteredAttrList.size() > 0) {
				for(Object obj :userEnteredAttrList) {
					Map<String, Object> userEnteredAttr = (Map<String, Object>) obj;
					if(userEnteredAttr.get('type') == 'Text' && userEnteredAttr.get('vType') =='Pre-Defined' && attrIdToLocaleName.isEmpty() == false) {
						userEnteredAttr.put('vText', attrIdToLocaleName.get((String)userEnteredAttr.get(MODEL_USER_ENTERED_ATTR_ID)));
					}
					if(attIdToLocaleUserEnteredAttributeName.isEmpty() == false) {
						userEnteredAttr.put('name', attIdToLocaleUserEnteredAttributeName.get((String)userEnteredAttr.get(MODEL_USER_ENTERED_ATTR_ID)));
					}
				}
			}
		}

		return jsonMap;
	}
	public static set<string> getCatalogNodeFromOptions(Map<String, Object> jsonMap) {
		set<string> products = new set<string>();
		Map<String, Object> optionGroups = (Map<String, Object>)jsonMap.get(MODEL_ATTR_GROUPS);
		if (optionGroups == null) {
			return null; //jsonMap;
		}

		for(String grpId: optionGroups.keyset()) {
			Map<String, Object> groupObj = (Map<String, Object>) optionGroups.get(grpId);
			system.debug('option group -->' + (String)groupObj.get(MODEL_ATTR_U_ID));
			List<Object> options = (List<Object>) groupObj.get(MODEL_ATTR_OPTIONS);
			
			for(Object temp : options){
				Map<String, Object> option = (Map<String, Object>) temp;
				if(groupObj.get('type') == 'regular') {
					//system.debug('option  -->' + (String)option.get('_idNodeRef'));
					//system.debug('option  -->' + option);
					products.add((String)option.get('_idNodeRef'));
				}
			}
			
		}
		system.debug('-----'+products.size());
		return products;
	}
	
    public static final String QUOTE_READY     = 'Ready';
	public static final String QUOTE_ORDERED   = 'Ordered';
	public static final String QUOTE_SUBMITTED = 'Submitted';
	public static final String QUOTE_DRAFT     = 'Draft';
	public static final String QUOTE_CLONING   = 'Cloning in progress...';
	public static final String QUOTE_VERSION_CLONING   = 'Revision in progress...';
	public static final String QUOTE_IN_PROCESS = 'In Process';
	public static final String GOAL_SEEK       = 'Target Price in progress...';
	public static final String QUOTE_CREATING_LINES  = 'Creating lines in progress...';
	public static final String QUOTE_CONTRACT_CREATED   = 'Contract Created';
	public static final String RECONFIG_INPROG = 'Re-Configure in progress...';
	public static final String QUOTE_CONVERTED_TO_CONTRACT   = 'Converted to Contract';
	public static final String QUOTE_PROCESSING_ORDER ='Processing Order';
	public static final String QUOTE_ORDER_FAILED ='Order Failed';
	public static final String QUOTE_EXPIRED = 'Expired';

	public static final String QUOTE_APPROVAL = 'Approval';
	public static final String QUOTE_NEGOTIATION = 'Negotiation';
	public static final String QUOTE_FINALIZED = 'Finalized';

	public static final String QUOTE_SALES_CONTRACT_TYPE = 'Sales Contract';
	public static final String QUOTE_SALES_CONTRACT_TYPE_DEV_NAME = 'SalesContract';
	public static final String GROUP_QUOTE_TYPE = 'Group Quote';
	public static final String GROUP_QUOTE_TYPE_DEV_NAME = 'Group_Quote';
	public static final String REGULAR_QUOTE_TYPE = 'Quote';

	public static final String QUOTE_ERROR_TYPE_TARGET_PRICE = 'Target Price';
	public static final String QUOTE_ERROR_TYPE_IMPORT = 'Import';
	public static final String QUOTE_ERROR_TYPE_RECONFIGURE  = 'Re-Configure';
	public static final String QUOTE_ERROR_TYPE_CREATE_IB_CONFIG = 'CreateIBConfig';
	public static final String QUOTE_ERROR_TYPE_CREATE_CONTRACT = 'CreateContract';
		public static final Set<String> QUOTE_MUST_HAVE_FIELDS = new Set<String> {
				'Quote_Value_Display_F__c',                 // First Year Value
				'Following_Years_Value_F__c',               // Following Years Value
				'Overall_Discount__c',                      // Total Discount
				'OneTimeTotalAfterAdjustmentDisplay_F__c',  // One-time Total
				'One_Time_Margin_F__c',                     // One-time Margins (%)
				'OneTimeTotalAdjustmentDisplay_F__c',       // One-time Discounts (%)
				'YearlyTotalAfterAdjustmentDisplay_F__c',
				'Yearly_Margin_F__c',
				'YearlyTotalAdjustmentDisplay_F__c',
				'MonthlyTotalAfterAdjustmentDisplay_F__c',
				'Monthly_Margin_F__c',
				'MonthlyTotalAdjustmentDisplay_F__c',
				'WeeklyTotalAfterAdjustmentDisplay_F__c',
				'Weekly_Margin_F__c',
				'WeeklyTotalAdjustmentDisplay_F__c',
				'ConfigitId__c',
				'SapBomUsage__c',
				'SapSalesDocumentType__c',
				'SapSalesOrg__c',
				'SapReqDeliveryDate__c',
				'SapPartnerCountry_F__c',
				'LifecycleConfig__c',
				'Phase__c',
				'Subphase__c',
				'Account__r.SapSalesOrg__c',
				'Account__r.SapPartnerCountry__c',
				'SapDistiChannel__c',
				'SapDivision__c',
				'ExtId__c',
				'QuoteConfig__c',
				'Price_Date__c',
				'One_Time_Line_Discount__c',
				'Yearly_Line_Discount__c',
				'Monthly_Line_Discount__c',
				'Weekly_Line_Discount__c',
				'Monthly_Total_Value_S__c',
				'Monthly_Value_Before_Discount_S__c',
				'Yearly_Total_Value_S__c',
				'Yearly_Value_Before_Discount_S__c',
				'Weekly_Total_Value_S__c',
				'Weekly_Value_Before_Discount_S__c',
				'One_Time_Total_Value_S__c',
				'One_Time_Value_Before_Discount_S__c',
				'One_Time_Line_Discount_Absolute__c',
				'Yearly_Line_Discount_Absolute__c',
				'Weekly_Line_Discount_Absolute__c',
				'Monthly_Line_Discount_Absolute__c',
				'CreatedDate',
				'LastModifiedDate',
				'Status__c',
				'Current_Status__c',
				'Opportunity__c',
				'Id__c',
				'Expiration_Date__c',
				'Account__c',
				'Account__r.AccountNumber',
				'Segment__c',
				'Currency__c',
				'Contact__c',
				'Contact__r.Email',
				'Contact__r.Phone',
				'Contact__r.FirstName',
				'Contact__r.LastName',
				'Contact__r.MailingStreet',
				'Contact__r.MailingCity',
				'Contact__r.MailingState',
				'Contact__r.MailingPostalCode',
				'Contact__r.MailingCountry',
				'Primary__c',
				'Name',
				'Owner.Id',
				'Owner.Name',
				'IsActiveVersion__c'    // A flag to determine is the Quote revision Active
	};
	public static final Set<String> QI_MUST_HAVE_FIELDS = new Set<String> {
				'Id__c',
				'Name',
				'Is_Configuration_Complete__c',
				'IsReConfigRequired__c',
				'ProductConfig__c',
				'ProductConfig__r.Id',
				'Product_ID_F__c',
				'Quote__c',
				'Catalog_Node__r.Model__c',
				'Catalog_Node__r.Configurable__c',
				'Catalog_Node__r.Name',
				'Catalog_Node__r.LocaleName_F__c',
				'Catalog_Node__r.Description__c',
				'Catalog_Node__r.LocaleDesc_RF__c',
				'Price__c',
				'Unit_Price__c',
				'Discount__c',
				'AutoDiscountType__c',
				'AutoDiscount__c',
				'AutoDiscountAbsolute__c',
				'AutoDiscountReason__c',
				'Quantity__c',
				'Catalog_Node__r.Type__c',
				'Catalog_Node__r.Billing_Frequency__c',
				'Catalog_Node__r.ProductAvailability__c',
				'Catalog_Node__r.InventoryLevel__c',
				'Catalog_Node__r.SapId__c',
				'Record_Number__c',
				'Catalog_Node__r.mainImage1__c',
				'Catalog_Node__r.Id__c',
				'Discount_Absolute__c',
				'Discount_Type__c',
				'VolDisc__c',
				'VolDiscAbsolute__c',
				'Extended_Price_F__c',
				'Catalog_Node__r.image2__c',
				'Catalog_Node__r.image3__c',
				'Catalog_Node__r.image4__c',
				'Monthly_Total_Value_F__c',
				'Monthly_Discount_F__c',
				'Monthly_Discount_Absolute_F__c',
				'Monthly_Extended_Price_F__c',
				'Monthly_Value_Before_Discount_F__c',
				'Yearly_Total_Value_F__c',
				'Yearly_Discount_F__c',
				'Yearly_Discount_Absolute_F__c',
				'Yearly_Extended_Price_F__c',
				'Yearly_Value_Before_Discount_F__c',
				'Weekly_Total_Value_F__c',
				'Weekly_Discount_F__c',
				'Weekly_Discount_Absolute_F__c',
				'Weekly_Extended_Price_F__c',
				'Weekly_Value_Before_Discount_F__c',
				'One_Time_Total_Value_F__c',
				'One_Time_Discount_F__c',
				'One_Time_Discount_Absolute_F__c',
				'One_Time_Extended_Price_F__c',
				'One_Time_Value_Before_Discount_F__c',
				'PricingSource__c',
				'IsSystemListPrice__c',
				'HasSubLineWithoutListPrice__c',
				'IsSystemUnitPrice__c',
				'ItemOption__c', 'PricingRuleMapping__c', 'AdjustmentRuleMapping__c', 'PricingRuleReason__c', 'AdjustmentRuleReason__c', 'AllPricingRules__c', 'AllAdjustmentRules__c',
				'Margin__c',
				'MarginAbsolute__c',
				'Adjustment1__c',
				'Adjustment1Absolute__c',
				'MarginType__c',
				'Adjustment1Type__c',
				'CostPrice__c',
				'IsSystemCostPrice__c',
				'Product_Type_F__c',
				'Billing_Frequency_WF__c',
				'UID__c',
				'QuoteSolution__c',
				'QuoteSolution__r.SolutionConfig__c',
				'QuoteSolution__r.Quote__c',
				'ConfigitQuoteItemId__c',
				'ConfigitMainItemId__c',
				'MainItemId__c',
				'SapPlant__c',
				'PriceListLine__c',
				'PriceListLine__r.PricingTier__c',
				'PriceListLine__r.PricingTier__r.Type__c',
				'Frozen__c',
				'Discountable__c',
				'FreezePricing__c',
				'IsBelowLine__c',
				'IsOutsideSolutionModel__c'
	};

	public static final Set<String> QUOTE_SUBLINE_MUST_HAVE_FIELDS = new Set<String> {
				'Id',
				'QuoteItem__c',
				'QuoteItem__r.ProductConfig__c',
				'QuoteItem__r.Quote__c',
				'Catalog_Node__r.Name',
				'Catalog_Node__r.LocaleName_F__c',
				'Price__c',
				'Unit_Price__c',
				'Discount__c',
				'VolDisc__c',
				'VolDiscAbsolute__c',
				'Quantity__c',
				'Extended_Price_F__c',
				'Catalog_Node__r.Type__c',
				'Catalog_Node__r.Billing_Frequency__c',
				'Catalog_Node__r.ProductAvailability__c',
				'Catalog_Node__r.InventoryLevel__c',
				'Catalog_Node__r.SapId__c',
				'Discount_Absolute__c',
				'Discount_Type__c',
				'Catalog_Node__r.Id__c',
				'UISection__c',
				'UID__c',
				'IsSystemListPrice__c',
				'IsSystemUnitPrice__c',
				'Margin__c',
				'MarginAbsolute__c',
				'Adjustment1__c',
				'Adjustment1Absolute__c',
				'MarginType__c',
				'Adjustment1Type__c',
				'CostPrice__c',
				'IsSystemCostPrice__c',
				'Catalog_Node__r.Description__c',
				'Catalog_Node__r.LocaleDesc_RF__c',
				'Catalog_Node__r.mainImage1__c',
				'Catalog_Node__r.image2__c',
				'Catalog_Node__r.image3__c',
				'Catalog_Node__r.image4__c',
				'Billing_Frequency_WF__c',
				'PriceListLine__c',
				'PriceListLine__r.PricingTier__c',
				'PriceListLine__r.PricingTier__r.Type__c',
				'Frozen__c',
				'Discountable__c',
				'FreezePricing__c',
				'QuoteItem__r.Quantity__c',
				'IsBelowLine__c'
	};

	public static final Set<String> QUOTE_SOLUTION_MUST_HAVE_FIELDS = new Set<String> {
				'Name',
				'IsConfigurationComplete__c',
				'IsItemsConfigurationComplete__c',
				'SolutionConfig__c',
				'SolutionConfig__r.Id',
				'CatalogNode__r.Model__c',
				'CatalogNode__r.Configurable__c',
				'CatalogNode__r.Name',
				'CatalogNode__r.LocaleName_F__c',
				'CatalogNode__r.Description__c',
				'CatalogNode__r.Type__c',
				'ExtId__c',
				'Quote__c'
	};

	public static final Set<String> QUOTE_SYSTEM_UPDATED_FIELDS = new Set<String> {
		'createddate',
		'createdbyid',
		'lastmodifieddate',
		'lastmodifiedbyid',
		'systemmodstamp',
		'lastactivitydate',
		'lastreferenceddate',
		'lastvieweddate',
		'phase__c',
		'subphase__c',
		'status__c',
		'current_status__c',
		'quote_status_image__c',
		'isactiveversion__c',
		'version_number__c',
		'errormessage__c',
		'primary__c',
		'extid__c'
	};

	//fields to check if quote item is changed or no (For marking services dirty).
	//TO DO: When we support discount fields in rules, then we need to add them here as well.
	public static final Set<String> QI_BOM_FIELDS = new Set<String> {
		'Quantity__c',
		'Price__c',
		'CostPrice__c',
		'Unit_Price__c'
	};

	public static final Set<String> IB_BOM_FIELDS = new Set<String> {
		'Quantity__c',
		'ListPrice__c',
		'CostPrice__c',
		'UnitPrice__c'
	};
	
	// Changes for SDR 343533
	public static final String QUOTE_DIP       = 'Draft in progress...';
	public static final String QUOTE_IMPORTING   = 'Importing Quote Lines';
	public static final String MODEL_ATTR_SECTION_NUMBER = 'sectionNumber';
	public static final String MODEL_ATTR_GROUP_NUMBER = 'groupNumber';
	public static final String MODEL_ATTR_SECTION_ID = 'sectionId';
	public static final String MODEL_ATTR_SECTION_NAME = 'sectionName';
	public static final String MODEL_ATTR_LAYOUT = 'layout';
	public static final String MODEL_ATTR_UI = 'UI';
	public static final String MODEL_ATTR_SECTIONS = 'sections';
	public static final String MODEL_ATTR_GROUPS = 'groups';
	public static final String MODEL_ATTR_OPTIONS = 'options';
	public static final String MODEL_USER_ENTERED_ATTRS = 'uea';
	public static final String MODEL_USER_ENTERED_ATTR_ID = 'attrId';
	public static final String MODEL_ALLOW_OVERRIDE = 'allowOverride';
	public static final String MODEL_ATTR_OPTION = 'option';
	public static final String MODEL_ATTR_NAME = 'name';
	public static final String MODEL_ATTR_UID = 'uid';
	public static final String MODEL_ATTR_U_ID = '_uid';
	public static final String MODEL_ATTR_USERSELECTED = '_userSelected';
	public static final String MODEL_ATTR_SELECTED = '_selected';
	public static final String MODEL_ATTR_SELECTION = '_selection';
	public static final String MODEL_ATTR_SYSTEM_SELECTION = 'systemSelected';
	public static final String MODEL_ATTR_OPTIONNUMBER = 'optionNumber';
	public static final String MODEL_ATTR_MANUAL_ADJUSTMENT = 'manAdj';
	public static final String MODEL_ATTR_IDNODE = 'idNode';
	public static final String MODEL_ATTR_QTY = 'qty';
	public static final String MODEL_ATTR_RESULT = 'result';
	public static final String MODEL_ATTR_QUOTES = 'quotes';
	public static final String MODEL_ATTR_OPTIONGROUP = 'optionGroup';
	public static final String MODEL_ATTR_UISECTIONNAME = 'uiSectionName';
	public static final String MODEL_ATTR_UISECTION = 'uiSection';
	public static final String MODEL_ATTR_PRODUCTID = 'prodId';
	public static final String MODEL_ATTR_P_RICE = 'listPrice';
	public static final String MODEL_ATTR_IS_SYS_LIST_PRICE = 'isSystemListPrice';
	public static final String MODEL_ATTR_IS_SYS_UNIT_PRICE = 'isSystemUnitPrice';
	public static final String MODEL_ATTR_IS_SYS_COST_PRICE = 'isSystemCostPrice';
	public static final String MODEL_ATTR_ADJUSTMENT1 = 'adj1';
	public static final String MODEL_ATTR_ADJUSTMENT1TYPE = 'adj1Type';
	public static final String MODEL_ATTR_ADJUSTMENT1VALUE = 'adj1Value';
	public static final String MODEL_ATTR_COST_PRICE = 'costPrice';
	public static final String MODEL_ATTR_UNIT_PRICE = 'unitPrice';
	public static final String MODEL_ATTR_PRICE = 'price';
	public static final String MODEL_ATTR_BILING_FREQUENCY = 'bilFreq';
	public static final String MODEL_ATTR_PRICE_FREQUENCY = 'priceFreq';
	public static final String MODEL_ATTR_CURRENCY = 'currency';
	public static final String MODEL_ATTR_QUANTITY = 'quantity';
	public static final String MODEL_ATTR_DISCOUNT_TYPE = 'discType';
	public static final String MODEL_ATTR_DISCOUNT_VALUE = 'discVal';
	public static final String MODEL_ATTR_VOL_DISCOUNT = 'volumeDiscount';
	public static final String MODEL_ATTR_VOL_DISCOUNT_TYPE = 'volDiscType';
	public static final String MODEL_ATTR_VOL_DISCOUNT_VALUE = 'volDiscValue';
	public static final String MODEL_ATTR_TYPE = 't';
	public static final String MODEL_ATTR_VALUE = 'v';
	public static final String MODEL_ATTR_DB_ID = 'dbId';
	public static final String MODEL_ATTR_EXPORT_SMDL = 'exportSMDL';
	public static final String MODEL_ATTR_SUBMODEL = 'subModel';
	public static final String MODEL_ATTR_DELETED = '_deleted';
	
	public static Map<String, String> createDisplayNameToLocaleName(List<Revvy__MnCatalogAttributeValue__c> attValues) {
		Map<String, String> IdcToLocaleName = new Map <String,String>();
		for (Revvy__MnCatalogAttributeValue__c attrVal : attValues) {
			IdcToLocaleName.put(attrVal.Revvy__Value_Display__c, attrVal.Revvy__LocaleDName_F__c);
		}
		return IdcToLocaleName;
	}
	
}