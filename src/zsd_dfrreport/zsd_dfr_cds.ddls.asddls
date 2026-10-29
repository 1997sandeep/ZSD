@EndUserText.label: 'DFR Report CDS Viw'
@ObjectModel.usageType:{
    serviceQuality: #X,
    sizeCategory: #S,
    dataClass: #MIXED
}
@ObjectModel: {
    query: {
        implementedBy: 'ABAP:ZCL_SDDFR_REPORT'
    }
}
define root custom entity ZSD_DFR_CDS

{
  @UI.selectionField: [{ position : 10 } ] 
  @Consumption.filter: { mandatory }
  @UI.lineItem      : [ { position: 10, label: 'Contract' }]
  @UI.identification: [{ position: 11, label: 'Contract' }]
  key ContractNumber : abap.char( 10 );
    @UI.selectionField: [{ position : 20 } ] 
//  @Consumption.filter: { mandatory }
  @UI.lineItem      : [ { position: 20, label: 'Sale Order' }]
  @UI.identification: [{ position: 12, label: 'Sale Order' }]
  key SaleOrder : vbeln;
    @UI.selectionField: [{ position : 30 } ] 
//  @Consumption.filter: { mandatory }
  @UI.lineItem      : [ { position: 30, label: 'RABillNumber' }]
  @UI.identification: [{ position: 13, label: 'RABillNumber' }]
  key RABillNumber : abap.char( 20 );
  key Period  : abap.char( 10 );
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
