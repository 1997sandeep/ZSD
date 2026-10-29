@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Client Billing F4'
@Metadata.ignorePropagatedAnnotations: true
define view entity zsd_taxinvoice_clntbilling_f4 as select from I_BillingDocument as A
{
  key  A.YY1_CustomBillingType_BDH
}
