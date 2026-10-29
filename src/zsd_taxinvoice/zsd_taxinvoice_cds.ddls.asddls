@EndUserText.label: 'Tax Invoice Custom Entity'
@ObjectModel.usageType:{
    serviceQuality: #X,
    sizeCategory: #S,
    dataClass: #MIXED
}
@ObjectModel: {
    query: {
        implementedBy: 'ABAP:ZCL_SDTAXINVOICE'
    }
}
define root custom entity ZSD_TAXINVOICE_CDS
 
{
  @UI.selectionField: [{ position : 10 } ] 
  @Consumption.filter: { mandatory }
  @UI.lineItem      : [ { position: 10, label: 'Document Number' }]
  @UI.identification: [{ position: 11, label: 'Document Number' }]
  key BillingDocument : vbeln;
   @UI.lineItem : [{ position: 20 }] 
 @EndUserText.label: 'Plant'
  Plant : werks_d;
   @UI.lineItem : [{ position: 30 }] 
 @EndUserText.label: 'Billing Type'
  BillingType : abap.char(10);
 @UI.lineItem : [{ position: 40 }] 
 @EndUserText.label: ' Filename'
// @UI.hidden: true
 FileName : abap.char( 128 );
 
 @UI.lineItem : [{ position: 50 }] 
 @EndUserText.label: 'Mime Type '
// @UI.hidden: true
 MimeType    : abap.char(128);
 
      @Semantics.largeObject:
                          { mimeType  : 'MimeType',
            fileName    : 'FileName'
            }
      @UI               : { lineItem:       [ { position: 410, label: 'Form'}],
             identification: [ { position: 410, label: 'Form'}] }
  Form          : abap.rawstring(0);
  
}
