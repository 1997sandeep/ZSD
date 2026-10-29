@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Billing Doc F4'
@Metadata.ignorePropagatedAnnotations: true
define view entity ZSD_TAXINVOICE_BILLF4 as select distinct from I_BillingDocument as A
left outer join I_BillingDocumentItem as c on ( c.BillingDocument = A.BillingDocument )
left outer join I_Customer as B on ( B.Customer = A.SoldToParty )
{
   key A.BillingDocument,
   A.YY1_CustomBillingType_BDH,
   B.CustomerFullName,
   c.Plant
} 
//where A.BillingDocumentIsCancelled = '' and ( A.BillingDocumentType = 'FZ' or A.BillingDocumentType = 'FAZ'
// )
