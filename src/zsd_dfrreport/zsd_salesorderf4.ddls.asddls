@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Sales Order F4'
@Metadata.ignorePropagatedAnnotations: true
define view entity ZSD_SalesOrderF4 as select distinct from I_SalesOrder as A
inner join I_SalesOrderItem as b on ( b.SalesOrder = A.SalesOrder )
{
    key A.SalesOrder,
     b.ReferenceSDDocument as contract
}
