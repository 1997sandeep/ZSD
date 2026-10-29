@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Outbound Delivery F4'
@Metadata.ignorePropagatedAnnotations: true
define view entity ZSD_Outbounddel_F4 as select  distinct from I_OutboundDelivery as A
left outer join I_OutboundDeliveryItem as b on ( b.OutboundDelivery = A.OutboundDelivery )
{
    key A.OutboundDelivery,
       b.Plant
}
