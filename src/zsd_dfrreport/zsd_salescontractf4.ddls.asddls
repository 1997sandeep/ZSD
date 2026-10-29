@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Sales Contract F4'
@Metadata.ignorePropagatedAnnotations: true
define view entity ZSD_SALESCONTRACTF4 as select distinct from I_SalesContract as a
{
   key  a.SalesContract
}
