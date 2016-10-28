/*
Version        : 1.0
Company        : Websolo Inc. (websolo.ca)
Date           : 07/2014
Update History :
*/
public class LeadConversionValidation
{
    public id leadobjid {get; set;}
    public String error {get; set;}
    public String reft {get;set;}
    public Boolean sterr {get; set;}
    public String sterrmsg {get; set;}
    public LeadConversionValidation(ApexPages.StandardController controller)
    {
      sterr = false;
      
      reft = '';
      error = '';
      leadobjid = ((Lead) controller.getRecord()).id;
      Lead leadobj = [select firstname,Contacted__c,Validated__c,Status, LastName, Email,Phone,Website,LeadSource,State,Street,City,PostalCode,Country from Lead where id =: leadobjid ];
      if(leadobj.firstname== null)
      { 
          reft = '1';
          sterrmsg = 'To convert Lead please change Lead Status to Contacted';
          if(error == '')
          {
              error = 'Please fill out following fields before conversion:<br />';
          }
          If(leadobj.firstname== null){error = error + '- The Lead must be have a First Name before it can be converted.<br />';}
          
      }
      if(leadObj.phone == null)
      {
          reft = '1';
          sterrmsg = 'To convert Lead please change Lead Status to Contacted';
          if(error == '')
          {
              error = 'Please fill out following fields before conversion:<br />';
          }
          error = error + '- The Lead must be have a full Phone Number before it can be converted.<br />';
      }         
      else if(leadObj.phone != null)
      {
          If(leadobj.phone.length() < 8)
          {
              reft = '1';
              sterrmsg = 'To convert Lead please change Lead Status to Contacted';
              if(error == '')
              {
                  error = 'Please fill out following fields before conversion:<br />';
              }
              error = error + '- The Lead must be have a full Phone Number before it can be converted.<br />';
          }
      }
      if((leadobj.country == 'US' || leadobj.country == 'USA') && leadobj.PostalCode == null) 
      {
          reft = '1';
          sterrmsg = 'To convert Lead please change Lead Status to Contacted';
          if(error == '')
          {
              error = 'Please fill out following fields before conversion:<br />';
          }
          error = error + '- The Lead must be have a valid Postal Code.<br />';
      }
      else if(((leadobj.country == 'US' || leadobj.country == 'USA') && leadobj.PostalCode != null))
      {
          if((leadobj.country == 'US' || leadobj.country == 'USA') && leadobj.PostalCode.length() < 5) 
          {
              reft = '1';
              sterrmsg = 'To convert Lead please change Lead Status to Contacted';
              if(error == '')
              {
                  error = 'Please fill out following fields before conversion:<br />';
              }
              error = error + '- The Lead must be have a valid Postal Code.<br />';
          }
      }
      if((leadobj.country == 'CA' || leadobj.country == 'CAN' || leadobj.country == 'Canada') && leadobj.PostalCode == null) 
      {
          reft = '1';
          sterrmsg = 'To convert Lead please change Lead Status to Contacted';
          if(error == '')
          {
              error = 'Please fill out following fields before conversion:<br />';
          }
          error = error + '- The Lead must be have a valid Postal Code.<br />';
      }
      else if((leadobj.country == 'CA' || leadobj.country == 'CAN' || leadobj.country == 'Canada') && leadobj.PostalCode !=null) 
      {
          if((leadobj.country == 'CA' || leadobj.country == 'CAN' || leadobj.country == 'Canada') && leadobj.PostalCode.length() < 7) 
          {
              reft = '1';
              sterrmsg = 'To convert Lead please change Lead Status to Contacted';
              if(error == '')
              {
                  error = 'Please fill out following fields before conversion:<br />';
              }
              error = error + '- The Lead must be have a valid Postal Code.<br />';
          }
      }
      if(leadobj.Status != 'Qualified')
      {
          reft = '1';
          sterrmsg = 'To convert Lead please change Lead Status to Contacted';
          if(error == '')
          {
              error = 'Please fill out following fields before conversion:<br />';
          }
          if(leadobj.Status != 'Qualified'){error = error + '- The Lead must have a Lead Status of Qualified before it can be converted.<br />';}
      }
    }
                 
}