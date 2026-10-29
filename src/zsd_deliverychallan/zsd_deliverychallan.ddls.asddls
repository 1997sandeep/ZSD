@EndUserText.label: 'Delivery challan Custom entity'
@ObjectModel.usageType:{
    serviceQuality: #X,
    sizeCategory: #S,
    dataClass: #MIXED
}
@ObjectModel: {
    query: {
        implementedBy: 'ABAP:ZCL_SDDELIVERYCHALLAN'
    }
}
define root custom entity ZSD_DELIVERYCHALLAN

{
  key DeliveryNumer : vgbel;
 key plant  : werks_d;
  key ChallanType : abap.char( 20 );
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
