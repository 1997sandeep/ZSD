@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Tax Invoice Plant F4'
@Metadata.ignorePropagatedAnnotations: true
define view entity ZSD_TAXINVOIVE_PLANT_F4 as select from I_Plant as a
{
    key a.Plant,
    a.PlantName
}
