CLASS zcl_sddeliverychallan DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    INTERFACES if_rap_query_provider .
  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS ZCL_SDDELIVERYCHALLAN IMPLEMENTATION.


  METHOD if_rap_query_provider~select.
  IF NOT io_request->is_data_requested( ).
      RETURN.
    ENDIF.

    DATA(filter) = io_request->get_filter( )->get_as_ranges(  ).
    TRY.
   READ TABLE filter INTO DATA(ls_filter) WITH KEY name = 'DELIVERYNUMER'.
IF sy-subrc = 0.
  DATA(lv_DOC) = ls_filter-range[ 1 ]-low.
ENDIF.
    READ TABLE filter INTO ls_filter WITH KEY name = 'PLANT'.
IF sy-subrc = 0.
  DATA(gv_PLANT) = ls_filter-range[ 1 ]-low.
ENDIF.

    READ TABLE filter INTO ls_filter WITH KEY name = 'CHALLANTYPE'.
IF sy-subrc = 0.
  DATA(lv_BT) = ls_filter-range[ 1 ]-low.
ENDIF.

      CATCH cx_rap_query_filter_no_range.
        RETURN.
    ENDTRY.

 DATA(paging) = io_request->get_paging( ).


DATA lv_del TYPE i_outbounddeliverytp-outbounddelivery.
 lv_del = lv_doc.


DATA: lv_plant     TYPE i_plant-plant,
      lv_delivery  TYPE i_outbounddeliverytp-outbounddelivery,
      lv_form_type TYPE c LENGTH 1.

DATA lv_form_title TYPE string.
lv_form_type = lv_bt.
lv_form_title = COND #( WHEN lv_form_type = 'J'
                        THEN 'JOB WORK CHALLAN'
                        ELSE 'DELIVERY CHALLAN' ).

*

TYPES: BEGIN OF ty_item,
         outbounddelivery        TYPE i_outbounddeliveryitem-outbounddelivery,
         outbounddeliveryitem    TYPE i_outbounddeliveryitem-outbounddeliveryitem,
         material                TYPE i_outbounddeliveryitem-material,
         product                 TYPE i_outbounddeliveryitem-product,
         plant                   TYPE i_outbounddeliveryitem-plant,
         itemtext                TYPE i_outbounddeliveryitem-deliverydocumentitemtext,
         originaldeliveryqty     TYPE i_outbounddeliveryitem-originaldeliveryquantity,
         baseunit                TYPE i_outbounddeliveryitem-baseunit,
         consumptiontaxctrlcode  TYPE i_productplantintltrd-consumptiontaxctrlcode,
         billingdocument         TYPE i_billingdocumentitem-billingdocument,
         billingdocumentitem     TYPE i_billingdocumentitem-billingdocumentitem,
         netamount               TYPE p LENGTH 13 DECIMALS 2,
         discount                TYPE p LENGTH 13 DECIMALS 2,
         totalamt                TYPE p LENGTH 13 DECIMALS 2,
         rate                    TYPE p LENGTH 13 DECIMALS 2,
         gstratetotal            TYPE p LENGTH 13 DECIMALS 2,
         cgstvalue               TYPE p LENGTH 13 DECIMALS 2,
         cgstamt                 TYPE p LENGTH 13 DECIMALS 2,
         sgstvalue               TYPE p LENGTH 13 DECIMALS 2,
         sgstamt                 TYPE p LENGTH 13 DECIMALS 2,
         igstvalue               TYPE p LENGTH 13 DECIMALS 2,
         igstamt                 TYPE p LENGTH 13 DECIMALS 2,
       END OF ty_item.

DATA it_item TYPE STANDARD TABLE OF ty_item WITH EMPTY KEY.

CONSTANTS: lc_cgst TYPE string VALUE 'JOCG',
           lc_sgst TYPE string VALUE 'JOSG',
           lc_igst TYPE string VALUE 'JOIG',
           lc_disc TYPE string VALUE 'ZCDP'.


lv_delivery = lv_doc.
lv_plant = gv_plant.
SELECT SINGLE FROM i_outbounddeliverytp
  FIELDS outbounddelivery,
         deliverydocumenttype,
         deliverydate,
         shiptoparty,
         yy1_ewaybillno_dlh,
         yy1_modeoftransport_dlh,
         yy1_transportername_dlh,
         yy1_transportergstin_dlh,
         yy1_motorvehicleno_dlh,
         yy1_billofladinglrrrno_dlh,
         yy1_remark_dlh,
         yy1_termsandcon1_dlh,
         YY1_TermsAndCondtion2_dlh,
         YY1_TermsAndCon3_DLH,
         yy1_termsandcondition4_dlh
  WHERE outbounddelivery = @lv_delivery
  INTO @DATA(wa_head).
*IF sy-subrc <> 0.
*  RETURN.
*ENDIF.


SELECT SINGLE FROM i_customer
  FIELDS customer,
         customername,
         bpaddrstreetname,
         bpaddrcityname,
         postalcode,
         country,
         region,
         taxnumber3
  WHERE customer = @wa_head-shiptoparty
  INTO @DATA(ls_party).

DATA lv_regionname TYPE string.
SELECT SINGLE FROM i_regiontext
  FIELDS regionname
  WHERE country  = 'IN'
    AND region   = @ls_party-region
    AND language = @sy-langu
  INTO @lv_regionname.


DATA(lv_regioncode) = ls_party-region.


DATA lv_pan TYPE string.
IF strlen( ls_party-taxnumber3 ) >= 12.
  lv_pan = ls_party-taxnumber3+2(10).
ENDIF.


SELECT FROM i_outbounddeliveryitem AS b
  LEFT OUTER JOIN i_productplantintltrd AS d
    ON  d~plant   = b~plant
    AND d~product = b~product
  FIELDS b~outbounddelivery,
         b~outbounddeliveryitem,
         b~material,
         b~product,
         b~plant,
         b~deliverydocumentitemtext AS itemtext,
         b~originaldeliveryquantity AS originaldeliveryqty,
         b~baseunit,
         d~consumptiontaxctrlcode
  WHERE b~outbounddelivery = @lv_delivery
    AND b~originaldeliveryquantity > 0
  ORDER BY b~outbounddeliveryitem
  INTO CORRESPONDING FIELDS OF TABLE @it_item.

*IF it_item IS INITIAL.
*  RETURN.
*ENDIF.


SELECT single FROM i_billingdocumentitem
  FIELDS max( billingdocument ) as billingdocument  ,
         billingdocumentitem,
         referencesddocument
  WHERE referencesddocument = @lv_delivery
  GROUP BY referencesddocument,billingdocumentitem
  INTO  @DATA(lt_billitem_c).



SELECT FROM i_billingdocumentitem
  FIELDS  billingdocument  ,
         billingdocumentitem,
         referencesddocument,
         referencesddocumentitem,
         plant,
         netamount
  WHERE BillingDocument = @lt_billitem_c-billingdocument
  INTO TABLE @DATA(lt_billitem).

LOOP AT it_item ASSIGNING FIELD-SYMBOL(<i>).
  DATA(ls_bi) = VALUE #( lt_billitem[ referencesddocumentitem = <i>-outbounddeliveryitem ] OPTIONAL ).
  <i>-billingdocument     = ls_bi-billingdocument.
  <i>-billingdocumentitem = ls_bi-billingdocumentitem.
  <i>-netamount           = ls_bi-netamount.
ENDLOOP.








IF lt_billitem IS NOT INITIAL.
  SELECT FROM i_billingdocitemprcgelmntbasic
    FIELDS billingdocument,
           billingdocumentitem,
           conditiontype,
           conditionratevalue,
           conditionamount
    FOR ALL ENTRIES IN @lt_billitem
    WHERE billingdocument = @lt_billitem-billingdocument
    INTO TABLE @DATA(lt_price).

  SELECT FROM i_billingdocitemprcgelmntbasic
    FIELDS billingdocument,
           billingdocumentitem,
           conditiontype,
           conditionratevalue,
           conditionamount
    FOR ALL ENTRIES IN @lt_billitem
    WHERE billingdocument = @lt_billitem-billingdocument
    and BillingDocumentItem = @lt_billitem-BillingDocumentItem
    and ConditionType in ( 'ZCON','ZERP','ZCHS','ZESP','ZASP','ZRPP','ZSRP','ZRPB','ZRRP','ZMSP' )
    INTO TABLE @DATA(lt_rate).
ENDIF.

LOOP AT it_item ASSIGNING FIELD-SYMBOL(<item>).

  LOOP AT lt_price INTO DATA(ls_p)
       WHERE billingdocument     = <item>-billingdocument
         AND billingdocumentitem = <item>-billingdocumentitem.

    CASE ls_p-conditiontype.
      WHEN lc_cgst.
        <item>-cgstvalue = ls_p-conditionratevalue.
        <item>-cgstamt   = <item>-cgstamt + ls_p-conditionamount.
      WHEN lc_sgst.
        <item>-sgstvalue = ls_p-conditionratevalue.
        <item>-sgstamt   = <item>-sgstamt + ls_p-conditionamount.
      WHEN lc_igst.
        <item>-igstvalue = ls_p-conditionratevalue.
        <item>-igstamt   = <item>-igstamt + ls_p-conditionamount.
      WHEN lc_disc.

        <item>-discount  = <item>-discount + abs( ls_p-conditionamount ).
    ENDCASE.

  ENDLOOP.

  LOOP AT lt_rate INTO DATA(ls_r).
*   WHERE billingdocument     = <item>-billingdocument
*         AND billingdocumentitem = <item>-billingdocumentitem.
     <item>-rate = <item>-rate +  ls_r-ConditionAmount.
       endloop.



  <item>-gstratetotal = <item>-cgstvalue + <item>-sgstvalue + <item>-igstvalue.



  <item>-totalamt = <item>-netamount + <item>-discount.


*  IF <item>-originaldeliveryqty IS NOT INITIAL.
*    <item>-rate = <item>-totalamt / <item>-originaldeliveryqty.
*  ENDIF.
<item>-rate = <item>-rate - <item>-discount.

ENDLOOP.


DATA: lvxml TYPE string.

DATA: sr                     TYPE i,
      taxablevalue           TYPE p LENGTH 13 DECIMALS 2,
      rate                   TYPE p LENGTH 13 DECIMALS 2,
      total_amt              TYPE p LENGTH 13 DECIMALS 2,
      discount               TYPE p LENGTH 13 DECIMALS 2,
      lv_line_tax            TYPE p LENGTH 13 DECIMALS 2,
      lv_cgst_per            TYPE p LENGTH 13 DECIMALS 2,
      lv_sgst_per            TYPE p LENGTH 13 DECIMALS 2,
      lv_igst_per            TYPE p LENGTH 13 DECIMALS 2,
      lv_cgst_amt            TYPE p LENGTH 13 DECIMALS 2,
      lv_sgst_amt            TYPE p LENGTH 13 DECIMALS 2,
      lv_igst_amt            TYPE p LENGTH 13 DECIMALS 2.

DATA: lv_total_taxable       TYPE p LENGTH 13 DECIMALS 2,
      lv_total_discount      TYPE p LENGTH 13 DECIMALS 2,
      cgst_amt_tot           TYPE p LENGTH 13 DECIMALS 2,
      sgst_amt_tot           TYPE p LENGTH 13 DECIMALS 2,
      igst_amt_tot           TYPE p LENGTH 13 DECIMALS 2,
      total_gst_val          TYPE p LENGTH 13 DECIMALS 2,
      lv_gross_raw           TYPE p LENGTH 13 DECIMALS 2,
      lv_gross               TYPE p LENGTH 13 DECIMALS 2,
      lv_roundoff            TYPE p LENGTH 13 DECIMALS 2,
      value                  TYPE string.


*&---------------------------------------------------------------------*
*&  OBSERVATION - header block comes from the PLANT
*&
*&      Plant   <- I_BillingDocumentItem-Plant
*&      Name    <- I_Plant-PlantName (+ PlantName2 when it differs)
*&      Address <- I_Plant-PlantCustomer -> I_Customer
*&      State   <- region -> I_RegionText-RegionName
*&      GSTIN   <- I_Plant-PlantCustomer -> I_Customer-TaxNumber3
*&      PAN     <- I_Plant-BusinessPlace -> I_BusinessPlace-TaxNumber1
*&
*&  No ADRC view is used. FNDEI_ADRC_FILTER does not exist in S/4HANA
*&  Public Cloud, and the _Address association on I_Plant is flagged
*&  Deprecated, so neither is a safe target. The plant address is taken
*&  from the plant's own customer master instead - I_Plant exposes
*&  PlantCustomer (KUNNR_WK) and I_Customer is already proven to work
*&  in this program. That same view also carries TaxNumber3, which
*&  closes the GSTIN gap: I_BusinessPlace exposes TaxNumber1/2/5 but
*&  not TaxNumber3.
*&
*&  I_Customer holds two address field sets. BPAddrStreetName came back
*&  blank for the plant customer on the last run, so StreetName /
*&  CityName are used as the fallback. If either fails the syntax check
*&  in your release, delete that half of the COND and keep the BPAddr*
*&  side only.
*&---------------------------------------------------------------------*
DATA: lv_hdr_plant    TYPE i_plant-plant,
      lv_plant_name   TYPE string,
      lv_plant_addr   TYPE string,
      lv_plant_gstin  TYPE string,
      lv_plant_state  TYPE string,
      lv_plant_street TYPE string,
      lv_plant_city   TYPE string,
      lv_plant_pan    TYPE string.

lv_hdr_plant = VALUE #( lt_billitem[ 1 ]-plant OPTIONAL ).
IF lv_hdr_plant IS INITIAL.
  lv_hdr_plant = VALUE #( it_item[ 1 ]-plant OPTIONAL ).
ENDIF.
IF lv_hdr_plant IS INITIAL.
  lv_hdr_plant = lv_plant.
ENDIF.

SELECT SINGLE FROM i_plant
  FIELDS plant, plantname, plantname2,
         businessplace,  plantcustomer ,AddressID
  WHERE plant = @lv_hdr_plant
  INTO @DATA(ls_plant).

IF ls_plant-AddressID IS NOT INITIAL.
  SELECT SINGLE FROM zaddress
    FIELDS
          StreetPrefixName1 && StreetPrefixName2 as StreetName,
           cityname,
           postalcode,
           country,
           region,
          CareOfName as taxnumber3
    WHERE AddressID = @ls_plant-AddressID
    INTO @DATA(ls_pcust).

  lv_plant_street = COND #( WHEN ls_pcust-streetname IS NOT INITIAL
                            THEN ls_pcust-streetname ELSE ls_pcust-streetname ).
  lv_plant_city   = COND #( WHEN ls_pcust-cityname IS NOT INITIAL
                            THEN ls_pcust-cityname   ELSE ls_pcust-cityname ).
  lv_plant_gstin  = ls_pcust-taxnumber3.

  DATA(lv_plant_ctry) = COND land1( WHEN ls_pcust-country IS NOT INITIAL
                                    THEN ls_pcust-country ELSE 'IN' ).

  SELECT SINGLE FROM i_regiontext
    FIELDS regionname
    WHERE country  = @lv_plant_ctry
      AND region   = @ls_pcust-region
      AND language = @sy-langu
    INTO @lv_plant_state.
ENDIF.

* PlantName2 is a real second name line only when it differs from
* PlantName - otherwise the header prints the same name twice.
lv_plant_name = ls_plant-plantname.
IF ls_plant-plantname2 IS NOT INITIAL AND
   ls_plant-plantname2 <> ls_plant-plantname.
  lv_plant_name = lv_plant_name && ` ` && ls_plant-plantname2.
ENDIF.

* The separator is only added when there is already something to
* separate from, otherwise a plant with no street prints a leading
* comma - ", Mumbai 400020 (Maharashtra)".
lv_plant_addr = lv_plant_street.
IF lv_plant_city IS NOT INITIAL.
  IF lv_plant_addr IS NOT INITIAL.
    lv_plant_addr = lv_plant_addr && `, `.
  ENDIF.
  lv_plant_addr = lv_plant_addr && lv_plant_city.
ENDIF.
IF ls_pcust-postalcode IS NOT INITIAL.
  IF lv_plant_addr IS NOT INITIAL.
    lv_plant_addr = lv_plant_addr && ` `.
  ENDIF.
  lv_plant_addr = lv_plant_addr && ls_pcust-postalcode.
ENDIF.
IF lv_plant_state IS NOT INITIAL.
  IF lv_plant_addr IS NOT INITIAL.
    lv_plant_addr = lv_plant_addr && ` `.
  ENDIF.
  lv_plant_addr = lv_plant_addr && `(` && lv_plant_state && `)`.
ENDIF.

* PAN from the business place. LV_PAN already holds the ship-to PAN as
* computed further up, so it is only overwritten when the plant lookup
* actually returns something - the header never falls back to blank.
IF ls_plant-businessplace IS NOT INITIAL.
  SELECT SINGLE FROM i_businessplace
    FIELDS taxnumber1
    WHERE
       businessplace = @ls_plant-businessplace
    INTO @lv_plant_pan.
ENDIF.

IF lv_plant_pan IS INITIAL AND strlen( lv_plant_gstin ) >= 12.
  lv_plant_pan = lv_plant_gstin+2(10).
ENDIF.
IF lv_plant_pan IS NOT INITIAL.
  lv_pan = lv_plant_pan.
ENDIF.

DATA: lv_party_addr TYPE string,
      lv_party_city TYPE string,
      lv_pos        TYPE string,
      lv_matnr      TYPE string.


lv_party_addr = ls_party-bpaddrstreetname.


lv_party_city = ls_party-bpaddrcityname.
IF ls_party-postalcode IS NOT INITIAL. lv_party_city = lv_party_city && ` `  && ls_party-postalcode. ENDIF.
IF lv_regionname       IS NOT INITIAL. lv_party_city = lv_party_city && ` (` && lv_regionname && `)`. ENDIF.

*  Place of Supply prints as "<RegionName> (<RegionCode>)"
lv_pos = lv_regionname.
IF lv_regioncode IS NOT INITIAL. lv_pos = lv_pos && ` (` && lv_regioncode && `)`. ENDIF.

*----------------------------------------------------------------------*
*  Header - title from the selection flag; name, address, GSTIN and
*  PAN all from the PLANT, per the observation.
*----------------------------------------------------------------------*
IF LV_BT = 'J'.
DATA(CHALLANTY) =
                         'JOB WORK CHALLAN'.
                         ELSE.
CHALLANTY =                'DELIVERY CHALLAN'.
ENDIF.
*data(test)  = 'TEST'.
lvxml =
|<form1>| &&
|<InvoiceBody>| &&
|<Header>| &&
|<HeaderBox01>| &&
|<TaxInvoice>{ CHALLANTY }</TaxInvoice>| &&
|</HeaderBox01>| &&
|<HeaderBox02>| &&
|<BillFromName>{ lv_plant_name }</BillFromName>| &&
|</HeaderBox02>| &&
|<HeaderBox03>| &&
|<BillFromAddress>{ lv_plant_addr }</BillFromAddress>| &&
|</HeaderBox03>| &&
|<HeaderBox04>| &&
|<BillFromGstin>{ 'GSTIN: ' && lv_plant_gstin }</BillFromGstin>| &&
|<Pan>{ 'PAN: ' && lv_pan }</Pan>| &&
|</HeaderBox04>| &&
|</Header>| &&

*----------------------------------------------------------------------*
*  Consigner / Dispatch From - the delivery's ship-to customer.
*  The label halves (InvoiceDate, EWayBillNo, DispatchedThrough,
*  TransporterName, TransporterGstin, MotorVehicleNo,
*  BillOfLadingLrRrNo) are static in the form; only *Data is sent.
*  Challan No is the outbound delivery; Date is DeliveryDate.
*----------------------------------------------------------------------*
|<Consigner>| &&
|<ConsignerBox01>| &&
|<ChallanNo>{ 'Challan No : ' && |{ wa_head-outbounddelivery ALPHA = OUT }| }</ChallanNo>| &&
|<InvoiceDateData>{ wa_head-deliverydate DATE = ENVIRONMENT }</InvoiceDateData>| &&
|</ConsignerBox01>| &&
|<ConsignerBox02>| &&
|<EWayBillNoData>{ wa_head-yy1_ewaybillno_dlh }</EWayBillNoData>| &&
|</ConsignerBox02>| &&
|<ConsignerBox03>| &&
|<DispatchFromName>{ ls_party-customername }</DispatchFromName>| &&
|<DispatchThroughData>{ wa_head-yy1_modeoftransport_dlh }</DispatchThroughData>| &&
|</ConsignerBox03>| &&
|<ConsignerBox04>| &&
|<DispatchFromAddress>{ lv_party_addr }</DispatchFromAddress>| &&
|<TransporterNameData>{ wa_head-yy1_transportername_dlh }</TransporterNameData>| &&
|</ConsignerBox04>| &&
|<ConsignerBox05>| &&
|<DispatchFromDistrict>{ lv_party_city }</DispatchFromDistrict>| &&
|<TransporterGstinData>{ wa_head-yy1_transportergstin_dlh }</TransporterGstinData>| &&
|</ConsignerBox05>| &&
|<ConsignerBox06>| &&
|<DispatchFromGstin>{ 'GSTIN: ' && ls_party-taxnumber3 }</DispatchFromGstin>| &&
|<VechileNodata>{ wa_head-yy1_motorvehicleno_dlh }</VechileNodata>| &&
|</ConsignerBox06>| &&
|<ConsignerBox07>| &&
|<Consigner0701></Consigner0701>| &&
|<Billoflandingdata>{ wa_head-yy1_billofladinglrrrno_dlh }</Billoflandingdata>| &&
|</ConsignerBox07>| &&
|</Consigner>| &&

*----------------------------------------------------------------------*
*  Consignee / Ship To - same customer as the block above, per the FS.
*  Place of Supply is that customer's region name plus region code.
*----------------------------------------------------------------------*
|<Consignee>| &&
|<PartyBox01></PartyBox01>| &&
|<PartyBox02>| &&
|<ShipToName>{ 'M/s. ' && ls_party-customername }</ShipToName>| &&
|<Palaceofsupplydata>{ lv_pos }</Palaceofsupplydata>| &&
|</PartyBox02>| &&
|<PartyBox03>| &&
|<Shiptoaddress>{ lv_party_addr }{ COND #( WHEN lv_party_city IS NOT INITIAL THEN |, { lv_party_city }| ) }</Shiptoaddress>| &&
|</PartyBox03>| &&
|<PartyBox04>| &&
|<ShiptoGstin>{ 'GSTIN: ' && ls_party-taxnumber3 }</ShiptoGstin>| &&
|<RemarksData>{ wa_head-yy1_remark_dlh }</RemarksData>| &&
|</PartyBox04>| &&
|</Consignee>| &&

|<ItemTable>| &&
|<ItemRow01></ItemRow01>|.

*----------------------------------------------------------------------*
*  Item rows
*  Description is DeliveryDocumentItemText, Qty is
*  OriginalDeliveryQuantity, Unit is BaseUnit.
*  Value (INR) is the gross line value, Discount is the ZCDP amount and
*  Taxable Value is Value - Discount, which reconciles to the billing
*  line NetAmount.
*----------------------------------------------------------------------*
CLEAR: sr, lv_total_taxable, lv_total_discount,
       cgst_amt_tot, sgst_amt_tot, igst_amt_tot.

LOOP AT it_item INTO DATA(wa_item).

  CLEAR: taxablevalue, rate, total_amt, discount, lv_line_tax.
  sr = sr + 1.

* strip leading zeros - an 18 digit material overflows the column
  lv_matnr = wa_item-material.
  SHIFT lv_matnr LEFT DELETING LEADING '0'.

  rate         = wa_item-rate.
  total_amt    = wa_item-totalamt.       " Value (INR) - gross
  discount     = wa_item-discount.       " Discount
  taxablevalue = total_amt - discount.   " Taxable Value = Value - Discount

  lv_cgst_per = wa_item-cgstvalue.
  lv_sgst_per = wa_item-sgstvalue.
  lv_igst_per = wa_item-igstvalue.
  lv_cgst_amt = wa_item-cgstamt.
  lv_sgst_amt = wa_item-sgstamt.
  lv_igst_amt = wa_item-igstamt.
  lv_line_tax = lv_cgst_amt + lv_sgst_amt + lv_igst_amt.

  lv_total_taxable  = lv_total_taxable  + taxablevalue.
  lv_total_discount = lv_total_discount + discount.
  cgst_amt_tot     = cgst_amt_tot     + lv_cgst_amt.
  sgst_amt_tot     = sgst_amt_tot     + lv_sgst_amt.
  igst_amt_tot     = igst_amt_tot     + lv_igst_amt.

  lvxml = lvxml &&
  |<ItemRow02>| &&
  |<SRNO>{ sr }</SRNO>| &&
  |<MaterialNo>{ lv_matnr }</MaterialNo>| &&
  |<Description>{ wa_item-itemtext }</Description>| &&
  |<HSN>{ wa_item-consumptiontaxctrlcode }</HSN>| &&
  |<uom>{ wa_item-baseunit }</uom>| &&
  |<qunatity>{ wa_item-originaldeliveryqty }</qunatity>| &&
  |<Rate>{ rate }</Rate>| &&
  |<TotalAmt>{ total_amt }</TotalAmt>| &&
  |<DiscountAmt>{ discount }</DiscountAmt>| &&
  |<Taxablevale>{ taxablevalue }</Taxablevale>| &&
  |<CgstPer>{ lv_cgst_per }</CgstPer>| &&
  |<CgstAmt>{ lv_cgst_amt }</CgstAmt>| &&
  |<SgstPer>{ lv_sgst_per }</SgstPer>| &&
  |<SgstAmt>{ lv_sgst_amt }</SgstAmt>| &&
  |<IgstPer>{ lv_igst_per }</IgstPer>| &&
  |<IgstAmt>{ lv_igst_amt }</IgstAmt>| &&
  |<TotalTaxAmt>{ lv_line_tax }</TotalTaxAmt>| &&
  |</ItemRow02>|.

ENDLOOP.

*----------------------------------------------------------------------*
*  Totals
*  Grand Total = taxable + CGST + SGST + IGST, per the FS. Aggregated
*  from the lines above so the summary can never disagree with what is
*  printed - which is why the invoice's four GROUP BY selects are not
*  carried over.
*  CGST/SGST and IGST are mutually exclusive; the form's initialize
*  script hides whichever pair is zero, so both are always sent.
*----------------------------------------------------------------------*
total_gst_val = cgst_amt_tot + sgst_amt_tot + igst_amt_tot.

lv_gross_raw = lv_total_taxable + total_gst_val.
lv_gross     = round( val = lv_gross_raw dec = 0 ).
lv_roundoff  = lv_gross - lv_gross_raw.

value = lv_gross.
CALL METHOD zcl_amttowords=>number2text
  EXPORTING value = value
  RECEIVING text  = DATA(words).

*----------------------------------------------------------------------*
*  Tax summary. ItemRow07 (Taxes / Rate header) and ItemRow12
*  (Total GST) are not in this form, so they are not sent. ItemRow15
*  comes before ItemRow13 - Round off prints under the gross.
*  The label cells are static; only the amounts are bound.
*----------------------------------------------------------------------*
lvxml = lvxml &&
|</ItemTable>| &&
|<TaxSummary>| &&
|<ItemRow06>| &&
|<Item0601></Item0601>| &&
|<TotalTaxableValueData>{ lv_total_taxable }</TotalTaxableValueData>| &&
|</ItemRow06>| &&
|<ItemRow08>| &&
|<Item0801></Item0801>| &&
|<CGSTAmt>{ cgst_amt_tot }</CGSTAmt>| &&
|</ItemRow08>| &&
|<ItemRow09>| &&
|<Item0901></Item0901>| &&
|<sgstamt>{ sgst_amt_tot }</sgstamt>| &&
|</ItemRow09>| &&
|<ItemRow10>| &&
|<Item1001></Item1001>| &&
|<Item1004>{ igst_amt_tot }</Item1004>| &&
|</ItemRow10>| &&
|<ItemRow15>| &&
|<Item1501></Item1501>| &&
|<TotalGROSSDATA>{ lv_gross }</TotalGROSSDATA>| &&
|</ItemRow15>| &&
|<ItemRow13>| &&
|<Item1301></Item1301>| &&
|<Roundoffdata>{ lv_roundoff }</Roundoffdata>| &&
|</ItemRow13>| &&
|</TaxSummary>| &&

*----------------------------------------------------------------------*
*  Footer. ForOmInfraLimitedKwar is static in the form, so FootBox03
*  is sent empty. Terms are the four manual VL01N fields. No bank block
*  on a challan, so FootBankBox / BankDetails / SignatoryArea are not
*  sent - AuthorisedSignatory is a static label inside TermsBox07.
*----------------------------------------------------------------------*
|<Footer>| &&
|<FootBox01>| &&
|<AmountInWordsData>{ words }</AmountInWordsData>| &&
|</FootBox01>| &&
|<FootBox02><Foot0201></Foot0201></FootBox02>| &&
|<FootBox03></FootBox03>| &&
|<TermsBox03>| &&
|<Terms0301>{ '1. ' && wa_head-YY1_Termsandcon1_DLH }</Terms0301>| &&
|<Terms0302></Terms0302>| &&
|</TermsBox03>| &&
|<TermsBox04>| &&
|<Terms0401>{ '2. ' && wa_head-YY1_TermsAndCondtion2_DLH }</Terms0401>| &&
|<Terms0402></Terms0402>| &&
|</TermsBox04>| &&
|<TermsBox05>| &&
|<Terms0501>{ '3. ' && wa_head-YY1_TermsAndCon3_DLH }</Terms0501>| &&
|<Terms0502></Terms0502>| &&
|</TermsBox05>| &&
|<TermsBox06>| &&
|<Terms0601>{ '4. ' && wa_head-yy1_termsandcondition4_dlh }</Terms0601>| &&
|<Terms0602></Terms0602>| &&
|</TermsBox06>| &&
|<TermsBox07>| &&
|<Terms0701></Terms0701>| &&
|</TermsBox07>| &&
|</Footer>| &&
|</InvoiceBody>| &&
|</form1>|.

  TRY.
        DATA(form) = cl_fp_form_reader=>create_form_reader( CONV #( |ZSD_DELIVERYCHALLAN_FORM| )  ).
      CATCH cx_fp_form_reader.
        "handle exception|
    ENDTRY.

 TRY.
        cl_fp_ads_util=>render_pdf(
            EXPORTING
                iv_locale       = 'en_US'
                iv_xdp_layout   = form->get_layout( )
                iv_xml_data     = xco_cp=>string( cl_web_http_utility=>encode_base64( lvxml ) )->as_xstring( xco_cp_binary=>text_encoding->base64 )->value
                is_options      = VALUE #(
                    "0 - only errors <= intended for production
                    "4 - very detailed trace <= intended for development
                    trace_level = 4
                    embed_fonts = form->get_font_embed( ) )
            IMPORTING
                ev_pdf          = DATA(pdf)
                ev_trace_string = DATA(logs)
        ).
      CATCH cx_fp_ads_util cx_fp_form_reader.
        "handle exception
    ENDTRY.

DATA : it_data TYPE table of zsd_deliverychallan.

it_data = VALUE #( for LS in IT_ITEM  (

DeliveryNumer = lv_delivery
PLANT  = ''
ChallanType = ''
FileName   = LS-BillingDocument  && '.' && 'PDF'
MimeType  = 'application/pdf'
Form   = pdf
) ).
SORT it_data by DeliveryNumer.
DELETE ADJACENT DUPLICATES FROM it_data COMPARING DeliveryNumer.



    io_response->set_data( IT_DATA ).
    io_response->set_total_number_of_records( lines( IT_DATA ) ).
  ENDMETHOD.
ENDCLASS.
