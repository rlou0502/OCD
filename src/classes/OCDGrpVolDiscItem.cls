/**
* @author Roy Lou
* @date 10/10/2016 
*
* @group Get Price
* @group-content ../../ApexDocContent/OCDGeneicTest.htm 
*
* @description This class is to store the adhoc Group Volume discount record data in the class:OCDSpecificDiscountCalc > method : updateNonStdVolumeDiscounts
* @Change History
*
*   Tag         Author              Date             Requested-BY      Description     
* *****************************************************************************************************************              
*   1.0.0      Roy Lou              10/10/2016        N/A               Initial Version                            
* *****************************************************************************************************************/

public with sharing class OCDGrpVolDiscItem {
    /*********************************************************************************************
    * @description Constructor
    **********************************************************************************************/	
	public OCDGrpVolDiscItem()
	{
		
	}
    /*********************************************************************************************
    * @description class variables
    **********************************************************************************************/	
	public Decimal qty = 0;
	public String basedOnPdts = null;
	public String appliedOnPdts = null;
	public Decimal minDiscount = 0;
	public Decimal maxDiscount = 0;
	public String discountGroupName =null;
	public String discountType =null;
	public String adjType = null;
	public String discCode = '';
	public String lob = '';

}