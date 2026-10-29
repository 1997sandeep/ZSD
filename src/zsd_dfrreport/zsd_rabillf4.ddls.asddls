@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'RA Bill F4'
@Metadata.ignorePropagatedAnnotations: true
define view entity ZSD_RABILLF4 as select distinct from I_SalesContract as A
left outer join I_SalesOrder as B on ( B.ReferenceSDDocument = A.SalesContract )
{
    key A.SalesContract,
    key B.SalesOrder,
    key B.PurchaseOrderByCustomer
       
}
