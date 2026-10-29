CLASS zcl_sdtaxinvoice DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
  DATA : LVXML TYPE STRING.
  INTERFACES if_rap_query_provider.
  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS ZCL_SDTAXINVOICE IMPLEMENTATION.


 METHOD if_rap_query_provider~select.


  IF NOT io_request->is_data_requested( ).
      RETURN.
    ENDIF.

    DATA(filter) = io_request->get_filter( )->get_as_ranges(  ).
    TRY.
   READ TABLE filter INTO DATA(ls_filter) WITH KEY name = 'BILLINGDOCUMENT'.
IF sy-subrc = 0.
  DATA(lv_DOC) = ls_filter-range[ 1 ]-low.
ENDIF.
    READ TABLE filter INTO ls_filter WITH KEY name = 'PLANT'.
IF sy-subrc = 0.
  DATA(lv_PLANT) = ls_filter-range[ 1 ]-low.
ENDIF.

    READ TABLE filter INTO ls_filter WITH KEY name = 'BILLINGTYPE'.
IF sy-subrc = 0.
  DATA(lv_BT) = ls_filter-range[ 1 ]-low.
ENDIF.

      CATCH cx_rap_query_filter_no_range.
        RETURN.
    ENDTRY.

 DATA(paging) = io_request->get_paging( ).


 """""Fectching Data""""""""""""""""""""

TYPES: BEGIN OF ty_item,
         billingdocument         TYPE i_billingdocumentitem-billingdocument,
         billingdocumentitem     TYPE i_billingdocumentitem-billingdocumentitem,
         billingquantity         TYPE i_billingdocumentitem-billingquantity,
         baseunit                TYPE i_billingdocumentitem-baseunit,
         material                TYPE i_billingdocumentitem-material,
         netamount               TYPE i_billingdocumentitem-netamount,
         productdescription      TYPE i_productdescription-productdescription,
         consumptiontaxctrlcode  TYPE i_productplantintltrd-consumptiontaxctrlcode,
         rate                    TYPE p LENGTH 13 DECIMALS 2,
         discount                TYPE p LENGTH 13 DECIMALS 2,
         totalamt                TYPE p LENGTH 13 DECIMALS 2,
         cgstvalue               TYPE p LENGTH 13 DECIMALS 2,
         cgstamt                 TYPE p LENGTH 13 DECIMALS 2,
         sgstvalue               TYPE p LENGTH 13 DECIMALS 2,
         sgstamt                 TYPE p LENGTH 13 DECIMALS 2,
         igstvalue               TYPE p LENGTH 13 DECIMALS 2,
         igstamt                 TYPE p LENGTH 13 DECIMALS 2,
       END OF ty_item.

DATA it_item TYPE STANDARD TABLE OF ty_item WITH EMPTY KEY.
DATA: lvxml TYPE string.

DATA: sr                     TYPE i,
      taxablevalue           TYPE p LENGTH 13 DECIMALS 2,
      rate                   TYPE p LENGTH 13 DECIMALS 2,
      total_amt              TYPE p LENGTH 13 DECIMALS 2,
      lv_line_tax            TYPE p LENGTH 13 DECIMALS 2,
      lv_cgst_per            TYPE p LENGTH 13 DECIMALS 2,
      lv_sgst_per            TYPE p LENGTH 13 DECIMALS 2,
      lv_igst_per            TYPE p LENGTH 13 DECIMALS 2,
      lv_cgst_amt            TYPE p LENGTH 13 DECIMALS 2,
      lv_sgst_amt            TYPE p LENGTH 13 DECIMALS 2,
      lv_igst_amt            TYPE p LENGTH 13 DECIMALS 2.

DATA: lv_sum_amount          TYPE p LENGTH 13 DECIMALS 2,
      lv_sum_discount        TYPE p LENGTH 13 DECIMALS 2,
      lv_total_taxable       TYPE p LENGTH 13 DECIMALS 2.

DATA: cgst_rate              TYPE p LENGTH 13 DECIMALS 2,
      sgst_rate              TYPE p LENGTH 13 DECIMALS 2,
      igst_rate              TYPE p LENGTH 13 DECIMALS 2,
      cgst_amt_tot           TYPE p LENGTH 13 DECIMALS 2,
      sgst_amt_tot           TYPE p LENGTH 13 DECIMALS 2,
      igst_amt_tot           TYPE p LENGTH 13 DECIMALS 2,
      total_gst              TYPE p LENGTH 13 DECIMALS 2,
      total_gst_val          TYPE p LENGTH 13 DECIMALS 2,
      lv_gross_raw           TYPE p LENGTH 13 DECIMALS 2,
      lv_gross               TYPE p LENGTH 13 DECIMALS 2,
      lv_roundoff            TYPE p LENGTH 13 DECIMALS 2,
       lv_total_gst_txt       TYPE string,
      lv_cgst_rate_txt       TYPE string,
      lv_sgst_rate_txt       TYPE string,
      lv_igst_rate_txt       TYPE string,
      value                  TYPE string.

*&---------------------------------------------------------------------*
*&  Summary rows of the new item-table footer
*&---------------------------------------------------------------------*
DATA: lv_frt_base TYPE p LENGTH 13 DECIMALS 2,
      lv_frt_cgst TYPE p LENGTH 13 DECIMALS 2,
      lv_frt_sgst TYPE p LENGTH 13 DECIMALS 2,
      lv_frt_igst TYPE p LENGTH 13 DECIMALS 2,
      lv_lod_base TYPE p LENGTH 13 DECIMALS 2,
      lv_lod_cgst TYPE p LENGTH 13 DECIMALS 2,
      lv_lod_sgst TYPE p LENGTH 13 DECIMALS 2,
      lv_lod_igst TYPE p LENGTH 13 DECIMALS 2,
      lv_tcs      TYPE p LENGTH 13 DECIMALS 2.

DATA: lv_tg_amt  TYPE p LENGTH 13 DECIMALS 2,
      lv_tg_tax  TYPE p LENGTH 13 DECIMALS 2,
      lv_tg_cgst TYPE p LENGTH 13 DECIMALS 2,
      lv_tg_sgst TYPE p LENGTH 13 DECIMALS 2,
      lv_tg_igst TYPE p LENGTH 13 DECIMALS 2,
      lv_gt_amt  TYPE p LENGTH 13 DECIMALS 2,
      lv_billval TYPE p LENGTH 13 DECIMALS 2.

*&  CHECK: condition types behind the Freight, Loading & Unloading and
*&  TCS rows. They are empty, so those three rows print zero until the
*&  functional consultant confirms which conditions your billing
*&  pricing procedure uses. Nothing else has to change.
DATA lr_freight TYPE RANGE OF i_billingdocitemprcgelmntbasic-conditiontype.
DATA lr_loading TYPE RANGE OF i_billingdocitemprcgelmntbasic-conditiontype.
DATA lr_tcs     TYPE RANGE OF i_billingdocitemprcgelmntbasic-conditiontype.

*lr_freight = VALUE #( sign = 'I' option = 'EQ' ( low = 'ZFB1' ) ( low = 'ZFA1' ) ).
*lr_loading = VALUE #( sign = 'I' option = 'EQ' ( low = 'ZC34' ) ).
*lr_tcs     = VALUE #( sign = 'I' option = 'EQ' ( low = 'ZTCS' ) ).

CONSTANTS: lc_cgst TYPE string VALUE 'JOCG',
           lc_sgst TYPE string VALUE 'JOSG',
           lc_igst TYPE string VALUE 'JOIG',
           lc_disc TYPE string VALUE 'ZCDP'.

DATA lt_base_cond TYPE RANGE OF i_billingdocitemprcgelmntbasic-conditiontype.
lt_base_cond = VALUE #( sign = 'I' option = 'EQ'
  ( low = 'ZCON' ) ( low = 'ZERP' ) ( low = 'ZCHS' ) ( low = 'ZROF' )
  ( low = 'ZESP' ) ( low = 'ZTCS' ) ( low = 'ZASP' ) ( low = 'ZRPP' )
  ( low = 'ZSRP' ) ( low = 'ZRPB' ) ( low = 'ZRRP' ) ( low = 'ZMSP' )
  ( low = 'ZCR' ) ( low = 'ZTRP' ) ( low = 'ZSUP' ) ( low = 'ZLC' ) ).


SELECT SINGLE FROM i_billingdocument
  FIELDS billingdocument,
         billingdocumentdate,
         soldtoparty,
         totalnetamount,
         yy1_refrencedate_bdh,
         yy1_referenceno_bdh,
         yy1_eximcode_bdh,
         yy1_irndate_bdh,
         yy1_irn_number_bdh,
         yy1_invoicenumber_bdh,
         yy1_lutnumber_bdh,
         yy1_modetermsofpayment_bdh,
         yy1_namebiller_bdh,
         yy1_otherreference_bdh,
         yy1_termsandcondition1_bdh,
         yy1_termsandcondition2_bdh,
         yy1_termsandcondition3_bdh,
         DocumentReferenceID
  WHERE billingdocument = @lv_doc
  INTO @DATA(wa_head).
IF sy-subrc <> 0.
  RETURN.
ENDIF.

SELECT FROM i_billingdocumentpartner
  FIELDS partnerfunction, customer
  WHERE billingdocument = @lv_doc
    AND partnerfunction IN ( 'AG', 'RE', 'WE', 'ZD' )
  INTO TABLE @DATA(lt_partner).

DATA(lv_soldto)  = VALUE #( lt_partner[ partnerfunction = 'AG' ]-customer OPTIONAL ).
DATA(lv_billto)  = VALUE #( lt_partner[ partnerfunction = 'RE' ]-customer OPTIONAL ).
DATA(lv_shipto)  = VALUE #( lt_partner[ partnerfunction = 'WE' ]-customer OPTIONAL ).
DATA(lv_dispto)  = VALUE #( lt_partner[ partnerfunction = 'ZD' ]-customer OPTIONAL ).

IF lv_dispto IS INITIAL.
  SELECT FROM i_billingdocumentitem AS a
    INNER JOIN i_salesorderpartner AS b
      ON  b~salesorder      = a~salesdocument
      AND b~partnerfunction = 'ZD'
    FIELDS b~customer
    WHERE a~billingdocument = @lv_doc
    ORDER BY a~billingdocumentitem
    INTO @lv_dispto
    UP TO 1 ROWS.
  ENDSELECT.
ENDIF.
IF lv_dispto IS INITIAL.
  lv_dispto = lv_soldto.
ENDIF.


IF lv_shipto IS INITIAL.
  lv_shipto = lv_billto.
ENDIF.

""""""BILLFROM

SELECT SINGLE FROM i_billingdocumentitem AS a
    INNER JOIN i_salesorderpartner AS b
      ON  b~salesorder      = a~salesdocument
      AND b~partnerfunction = '3R'
    FIELDS b~customer
    WHERE a~billingdocument = @lv_doc
    INTO @DATA(BILL_F_CUS).

SELECT  FROM i_customer
  FIELDS customer, customername, addressid, cityname, streetname,
         postalcode, country, region, taxnumber3
  WHERE customer = @BILL_F_CUS
  INTO TABLE @DATA(lt_shipfrom).

  SELECT FROM i_regiontext
  FIELDS country, region, regionname
  FOR ALL ENTRIES IN @lt_shipfrom
  WHERE country  = @lt_shipfrom-country
    AND region   = @lt_shipfrom-region
    AND language = @sy-langu
  INTO TABLE @DATA(lt_region_f).


  """"""""""""""""""""""""""""""""""""""""
SELECT FROM i_customer
  FIELDS customer, customername, addressid, cityname, streetname,
         postalcode, country, region, taxnumber3
  WHERE customer IN ( @lv_soldto, @lv_billto, @lv_shipto, @lv_dispto )
  INTO TABLE @DATA(lt_cust).


DATA lr_supp  TYPE RANGE OF i_customer-customer.
DATA lt_party TYPE STANDARD TABLE OF i_customer-customer WITH EMPTY KEY.

lt_party = VALUE #( ( lv_soldto ) ( lv_billto ) ( lv_shipto ) ( lv_dispto ) ).

LOOP AT lt_party INTO DATA(lv_party).

  CHECK lv_party IS NOT INITIAL.
  CHECK NOT line_exists( lt_cust[ customer = lv_party ] ).
  CHECK NOT line_exists( lr_supp[ low = lv_party ] ).
  APPEND VALUE #( sign = 'I' option = 'EQ' low = lv_party ) TO lr_supp.
ENDLOOP.

IF lr_supp IS NOT INITIAL.
  SELECT FROM i_supplier
    FIELDS supplier     AS customer,
           suppliername AS customername,
           addressid,
           cityname,
           streetname,
           postalcode,
           country,
           region,
           taxnumber3
    WHERE supplier IN @lr_supp
    APPENDING CORRESPONDING FIELDS OF TABLE @lt_cust.
ENDIF.

SELECT FROM i_regiontext
  FIELDS country, region, regionname
  FOR ALL ENTRIES IN @lt_cust
  WHERE country  = @lt_cust-country
    AND region   = @lt_cust-region
    AND language = @sy-langu
  INTO TABLE @DATA(lt_region).

DATA(ls_billfrom)  = VALUE #( lt_shipfrom[ customer = BILL_F_CUS ] OPTIONAL ).
DATA(ls_billtoadd) = VALUE #( lt_cust[ customer = lv_billto ] OPTIONAL ).
DATA(ls_shiptoadd) = VALUE #( lt_cust[ customer = lv_shipto ] OPTIONAL ).
DATA(ls_dispadd)   = VALUE #( lt_cust[ customer = lv_dispto ] OPTIONAL ).

DATA(ls_billfreg)  = VALUE #( lt_region_f[ country = ls_billfrom-country  region = ls_billfrom-region  ] OPTIONAL ).
DATA(ls_billtoreg) = VALUE #( lt_region[ country = ls_billtoadd-country region = ls_billtoadd-region ] OPTIONAL ).
DATA(ls_shiptoreg) = VALUE #( lt_region[ country = ls_shiptoadd-country region = ls_shiptoadd-region ] OPTIONAL ).
DATA(ls_consireg)  = VALUE #( lt_region[ country = ls_dispadd-country   region = ls_dispadd-region   ] OPTIONAL ).


SELECT FROM i_billingdocumentitem AS b
  INNER JOIN i_productdescription AS c
    ON  c~product  = b~product
    AND c~language = @sy-langu
  LEFT OUTER JOIN i_productplantintltrd AS d
    ON  d~plant   = b~plant
    AND d~product = b~product
  FIELDS b~billingdocument,
         b~billingdocumentitem,
         b~billingquantity,
         b~baseunit,
         b~material,
         b~netamount,
         c~productdescription,
         d~consumptiontaxctrlcode
  WHERE b~billingdocument = @lv_doc
  ORDER BY b~billingdocumentitem
  INTO CORRESPONDING FIELDS OF TABLE @it_item.


SELECT FROM i_billingdocitemprcgelmntbasic
  FIELDS billingdocumentitem,
         conditiontype,
         conditionratevalue,
         conditionrateratio,
         conditionamount
  WHERE billingdocument = @lv_doc
  INTO TABLE @DATA(lt_price).

LOOP AT it_item ASSIGNING FIELD-SYMBOL(<item>).

  LOOP AT lt_price INTO DATA(ls_p)
       WHERE billingdocumentitem = <item>-billingdocumentitem.

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
        <item>-discount  = <item>-discount + ls_p-conditionamount.
      WHEN OTHERS.
        IF ls_p-conditiontype IN lt_base_cond.
          <item>-totalamt = <item>-totalamt + ls_p-conditionamount.
          IF <item>-rate IS INITIAL.
            <item>-rate = ls_p-conditionratevalue.
          ENDIF.
        ENDIF.
    ENDCASE.

  ENDLOOP.
ENDLOOP.


SELECT SINGLE FROM i_billingdocumentbasic
  FIELDS yy1_bankacccountbnn_bdh,
         yy1_bankacccountbn_bdh,
         yy1_bankacccountcc_bdh,
         yy1_bankacccounthba_bdh,
         yy1_bankacccounthb_bdh,
         yy1_bankacccountifsc_bdh,
         yy1_custombillingtype_bdh,
         yy1_remarks_bdh,
         yy1_dispatchdocno_bdh,
         yy1_modeofpayment_bdh,
         yy1_dispatchthrough_bdh
  WHERE billingdocument = @lv_doc
  INTO @DATA(ls_bank).

  SELECT SINGLE FROM I_Bank_2
  FIELDS
  StreetName
  WHERE BankInternalID = @ls_bank-yy1_bankacccountifsc_bdh
  into @data(bank_add).



SELECT FROM i_billingdocumentitem AS a
  LEFT OUTER JOIN i_outbounddeliverytp AS b
    ON b~outbounddelivery = a~referencesddocument
  FIELDS a~billingdocument,
         b~yy1_ewaybillno_dlh,
         b~yy1_billofladinglrrrno_dlh,
         b~yy1_ewaybilldate_dlh,
         b~yy1_deliverynotedate_dlh,
         b~yy1_motorvehicleno_dlh,
         b~yy1_deliverynote_dlh
  WHERE a~billingdocument = @lv_doc
  ORDER BY a~billingdocumentitem
  INTO @DATA(ls_delivery)
  UP TO 1 ROWS.
ENDSELECT.


SELECT FROM i_billingdocitemprcgelmntbasic
  FIELDS conditionrateratio,
         SUM( conditionamount ) AS amt
  WHERE billingdocument = @lv_doc
    AND conditiontype   = @lc_cgst
  GROUP BY conditionrateratio
  INTO TABLE @DATA(lt_cgst).

SELECT FROM i_billingdocitemprcgelmntbasic
  FIELDS conditionrateratio,
         SUM( conditionamount ) AS amt
  WHERE billingdocument = @lv_doc
    AND conditiontype   = @lc_sgst
  GROUP BY conditionrateratio
  INTO TABLE @DATA(lt_sgst).

SELECT FROM i_billingdocitemprcgelmntbasic
  FIELDS conditionrateratio,
         SUM( conditionamount ) AS amt
  WHERE billingdocument = @lv_doc
    AND conditiontype   = @lc_igst
  GROUP BY conditionrateratio
  INTO TABLE @DATA(lt_igst).


data(ewaydate) = |{ ls_delivery-YY1_EWAYBillDate_DLH date = ENVIRONMENT }|.




lvxml =
|<form1>| &&
|<InvoiceBody>| &&
|<Header>| &&
|<HeaderBox01>| &&
|<TaxInvoice>Tax Invoice</TaxInvoice>| &&
|</HeaderBox01>| &&
|<HeaderBox02>| &&
|<Irn>{ 'IRN-' && wa_head-yy1_irn_number_bdh }</Irn>| &&
|</HeaderBox02>| &&
|<HeaderBox03>| &&
|<Header0302>{ wa_head-yy1_irndate_bdh DATE = ENVIRONMENT }</Header0302>| &&
|<Header0303></Header0303>| &&
|</HeaderBox03>| &&
|<HeaderBox04>| &&
|<Header0401></Header0401>| &&
|<EWayBillNo>{ 'E Way Bill No-' && ls_delivery-yy1_ewaybillno_dlh }</EWayBillNo>| &&
|</HeaderBox04>| &&
|<HeaderBox05>| &&
|<BillFrom>Bill From</BillFrom>| &&
|<EWayBillDate>{ 'E Way Bill Date-' && ewaydate }</EWayBillDate>| &&
|<Header0503></Header0503>| &&
|</HeaderBox05>| &&
|<HeaderBox06>| &&
|<BillFromName>{ ls_billfrom-customername }</BillFromName>| &&
|</HeaderBox06>| &&
|<HeaderBox07>| &&
|<BillFromAddress>{ 'Address-' && ls_billfrom-streetname }</BillFromAddress>| &&
|<InvoiceNoData>{ wa_head-DocumentReferenceID }</InvoiceNoData>| &&
|<InvoiceDateData>{ wa_head-billingdocumentdate DATE = ENVIRONMENT }</InvoiceDateData>| &&
|</HeaderBox07>| &&
|<HeaderBox08>| &&
|<BillFromDistrict>{ 'District-' && ls_billfrom-cityname }</BillFromDistrict>| &&
|<BillFromStateNameCode>{ 'State Name Code-' && ls_billfreg-regionname &&   '( ' && ls_billfrom-Region   &&  ')' }</BillFromStateNameCode>| &&
|</HeaderBox08>| &&
|<HeaderBox09>| &&

|<DeliveryNoteData>{ ls_delivery-yy1_deliverynote_dlh }</DeliveryNoteData>| &&
|<TermsofpaymentData>{ wa_head-yy1_modetermsofpayment_bdh }</TermsofpaymentData>| &&
|</HeaderBox09>| &&
|<HeaderBox10>| &&
|<BillfromCountry>{ 'Country-' && ls_billfrom-country }</BillfromCountry>| &&
|<BillFromPincode>{ 'Pincode-' && ls_billfrom-postalcode }</BillFromPincode>| &&
|</HeaderBox10>| &&
|<HeaderBox11>| &&
|<BillFromGstin>{ 'GSTIN/UIN:' && ls_billfrom-taxnumber3 }</BillFromGstin>| &&
|<Refrencenodata>{  wa_head-yy1_referenceno_bdh && '/' && wa_head-yy1_refrencedate_bdh  }</Refrencenodata>| &&
|<OtherRefData>{ wa_head-yy1_otherreference_bdh }</OtherRefData>| &&
|</HeaderBox11>| &&
|<HeaderBox12>| &&
|<Header1201></Header1201>| &&
|</HeaderBox12>| &&
|</Header>| &&

|<Consigner>| &&
|<ConsignerBox01>| &&
|<LUTNoData>{ wa_head-yy1_lutnumber_bdh }</LUTNoData>| &&
|<EximCodeData>{ wa_head-yy1_eximcode_bdh }</EximCodeData>| &&
|</ConsignerBox01>| &&
|<ConsignerBox02>| &&
|<DispatchFromName>{ ls_dispadd-customername }</DispatchFromName>| &&
|<Consigner0204></Consigner0204>| &&
|</ConsignerBox02>| &&
|<ConsignerBox03>| &&
|<DispatchFromAddress>{ 'Address-' && ls_dispadd-streetname }</DispatchFromAddress>| &&
|<DispatchDocData>{ ls_bank-yy1_dispatchdocno_bdh }</DispatchDocData>| &&
|<DeliverydateData>{ ls_delivery-yy1_deliverynotedate_dlh DATE = ENVIRONMENT }</DeliverydateData>| &&
|</ConsignerBox03>| &&
|<ConsignerBox04>| &&
|<DispatchFromDistrict>{ 'District-' && ls_dispadd-cityname }</DispatchFromDistrict>| &&
|<DispatchFromStateNameCode>{ 'State Name Code-' && ls_consireg-regionname && '(' && ls_dispadd-Region && ')' }</DispatchFromStateNameCode>| &&
|</ConsignerBox04>| &&
|<ConsignerBox05>| &&
|<DispatchFromCountry>{ 'Country-' && ls_dispadd-country }</DispatchFromCountry>| &&
|<DispatchFromPincode>{ 'Pincode-' && ls_dispadd-postalcode }</DispatchFromPincode>| &&
|<DispatchThroughData>{ ls_bank-yy1_dispatchthrough_bdh }</DispatchThroughData>| &&
|<Palaceofsupplydata>{ ls_billfreg-regionname }</Palaceofsupplydata>| &&
|</ConsignerBox05>| &&
|<ConsignerBox06>| &&
|<DispatchFromGstin>{ 'GSTIN/UIN:' && ls_dispadd-taxnumber3 }</DispatchFromGstin>| &&
|</ConsignerBox06>| &&
|<ConsignerBox07>| &&
|<Consigner0701></Consigner0701>| &&
|<Billoflandingdata>{ ls_delivery-yy1_billofladinglrrrno_dlh }</Billoflandingdata>| &&
|<VechileNodata>{ ls_delivery-yy1_motorvehicleno_dlh }</VechileNodata>| &&
|</ConsignerBox07>| &&
|</Consigner>| &&

|<Consignee>| &&
|<ConsigneeBox01>| &&
|<rcmapp>{ 'RCM Applicable :' && wa_head-YY1_InvoiceNumber_BDH }</rcmapp>| &&
|</ConsigneeBox01>| &&
|<ConsigneeBody>| &&
|<ConsigneeParties>| &&
|<PartyBox01><BillToName>{ ls_billtoadd-customername }</BillToName></PartyBox01>| &&
|<PartyBox02><BillToAddress>{ 'Address-' && ls_billtoadd-streetname }</BillToAddress></PartyBox02>| &&
|<PartyBox03>| &&
|<BilltoDistrict>{ 'District-' && ls_billtoadd-cityname }</BilltoDistrict>| &&
|<BilltoStateName>{ 'State Name Code-' && ls_billtoreg-regionname && '(' && ls_billtoadd-Region && ')' }</BilltoStateName>| &&
|</PartyBox03>| &&
|<PartyBox04>| &&
|<BilltoCountry>{ 'Country-' && ls_billtoadd-country }</BilltoCountry>| &&
|<BillToPincode>{ 'Pincode-' && ls_billtoadd-postalcode }</BillToPincode>| &&
|</PartyBox04>| &&
|<PartyBox05><BillltoGSTIN>{ 'GSTIN/UIN:' && ls_billtoadd-taxnumber3 }</BillltoGSTIN></PartyBox05>| &&
|<PartyBox06><Party0601></Party0601></PartyBox06>| &&
|<PartyBox07></PartyBox07>| &&
|<PartyBox08><ShipToName>{ ls_shiptoadd-customername }</ShipToName></PartyBox08>| &&
|<PartyBox09><Shiptoaddress>{ 'Address-' && ls_shiptoadd-streetname }</Shiptoaddress></PartyBox09>| &&
|<PartyBox10>| &&
|<ShiptoDistrict>{ 'District-' && ls_shiptoadd-cityname }</ShiptoDistrict>| &&
|<ShiptoStatecode>{ 'State Name Code-' && ls_shiptoreg-regionname && '(' && ls_shiptoreg-Region && ')' }</ShiptoStatecode>| &&
|</PartyBox10>| &&
|<PartyBox11>| &&
|<ShiptoCountry>{ 'Country-' && ls_shiptoadd-country }</ShiptoCountry>| &&
|<Shiptopincod>{ 'Pincode-' && ls_shiptoadd-postalcode }</Shiptopincod>| &&
|</PartyBox11>| &&
|<PartyBox12><ShiptoGstin>{ 'GSTIN/UIN:' && ls_shiptoadd-taxnumber3 }</ShiptoGstin></PartyBox12>| &&
|<PartyBox13></PartyBox13>| &&
|</ConsigneeParties>| &&
|<RemarksArea>| &&
|<RemarksBox01>| &&
|<RemarksData>{ ls_bank-yy1_remarks_bdh }</RemarksData>| &&
|</RemarksBox01>| &&
|</RemarksArea>| &&
|</ConsigneeBody>| &&
|</Consignee>| &&

|<ItemTable>| &&
|<ItemRow01></ItemRow01>|.

CLEAR: sr, lv_sum_amount, lv_sum_discount.

LOOP AT it_item INTO DATA(wa_item).

  CLEAR: taxablevalue, rate, total_amt, lv_line_tax.
  sr = sr + 1.


  DATA material TYPE string.
  IF ls_bank-yy1_custombillingtype_bdh = '101' AND wa_item-material CS '-'.
    SPLIT wa_item-material AT '-' INTO DATA(lv1) DATA(bbu_no).
    material = bbu_no.
  ELSE.
    material = wa_item-material.
  ENDIF.

  SHIFT material LEFT DELETING LEADING '0'.

*  total_amt = wa_item-billingquantity * wa_item-rate.
  total_amt = wa_item-totalamt.
  rate      = wa_item-rate.


  taxablevalue = total_amt + wa_item-discount.

  lv_cgst_per = wa_item-cgstvalue.
  lv_sgst_per = wa_item-sgstvalue.
  lv_igst_per = wa_item-igstvalue.
*  lv_cgst_amt = wa_item-cgstamt.
  lv_cgst_amt = ( taxablevalue * lv_cgst_per ) / 100 .
*  lv_cgst_amt = wa_item-cgstamt.
  lv_sgst_amt = ( taxablevalue * lv_sgst_per ) / 100 ..
*  lv_sgst_amt = wa_item-sgstamt.
  lv_igst_amt = ( taxablevalue * lv_igst_per ) / 100 ..
*  lv_igst_amt = wa_item-igstamt.
  lv_line_tax = lv_cgst_amt + lv_sgst_amt + lv_igst_amt.

  lv_sum_amount   = lv_sum_amount   + total_amt.
  lv_sum_discount = lv_sum_discount + wa_item-discount.
DATA : materialdis TYPE string.
materialdis = wa_item-productdescription.
  lvxml = lvxml &&
  |<ItemRow02>| &&
  |<SRNO>{ sr }</SRNO>| &&
  |<BBUNO>{ zcl_xml_util=>escape_for_xml( material ) }</BBUNO>| &&
  |<Description>{ zcl_xml_util=>escape_for_xml( materialdis ) }</Description>| &&
  |<HSN>{ wa_item-consumptiontaxctrlcode }</HSN>| &&
  |<uom>{ wa_item-baseunit }</uom>| &&
  |<qunatity>{ wa_item-billingquantity }</qunatity>| &&
  |<Rate>{ rate }</Rate>| &&
  |<TotalAmt>{ total_amt }</TotalAmt>| &&
  |<DiscountAmt>{ wa_item-discount }</DiscountAmt>| &&
  |<Taxablevale>{ taxablevalue }</Taxablevale>| &&
  |<CgstPer>{ lv_cgst_per }</CgstPer>| &&
  |<CgstAmt>{ lv_cgst_amt }</CgstAmt>| &&
  |<SgstPer>{ lv_sgst_per }</SgstPer>| &&
  |<SgstAmt>{ lv_sgst_amt }</SgstAmt>| &&
  |<IgstPer>{ lv_igst_per }</IgstPer>| &&
  |<IgstAmt>{ lv_igst_amt }</IgstAmt>| &&
  |<Item0217>{ lv_line_tax + taxablevalue }</Item0217>| &&
  |</ItemRow02>|.



  data : fright_cgst(1) type n,
         fright_sgst(1) type n,
         fright_igst(2) type n,
         load_cgst(1) type n,
         load_sgst(1) type n,
         load_igst(2) type n,
         totcgst type string,
         totsgst type string,
         totigst type string.
         .
   IF lv_cgst_per = '9'.
     fright_cgst = lv_cgst_per.
   ENDIF.
   IF lv_sgst_per = '9'.
     fright_sgst =  lv_sgst_per.
   ENDIF.
   IF lv_igst_per = '18'.
     fright_igst     =  lv_igst_per.
   ENDIF.
   IF lv_cgst_per = '9'.
     load_cgst = lv_cgst_per.
   ENDIF.
   IF lv_sgst_per = '9'.
     load_sgst =  lv_sgst_per.
   ENDIF.
   IF lv_igst_per = '18'.
     load_igst =  lv_igst_per.
   ENDIF.
totcgst  = totcgst + lv_cgst_amt.
totsgst  = totsgst + lv_sgst_amt.
totigst  = totigst + lv_igst_amt.



ENDLOOP.

*----------------------------------------------------------------------*
*  Totals
*----------------------------------------------------------------------*
lv_total_taxable = lv_sum_amount + lv_sum_discount.


CLEAR: cgst_amt_tot, sgst_amt_tot, igst_amt_tot.
LOOP AT lt_cgst INTO DATA(wa_cgst).
  cgst_amt_tot = cgst_amt_tot + wa_cgst-amt.
ENDLOOP.
LOOP AT lt_sgst INTO DATA(wa_sgst).
  sgst_amt_tot = sgst_amt_tot + wa_sgst-amt.
ENDLOOP.
LOOP AT lt_igst INTO DATA(wa_igst).
  igst_amt_tot = igst_amt_tot + wa_igst-amt.
ENDLOOP.

total_gst_val = cgst_amt_tot + sgst_amt_tot + igst_amt_tot.


lv_gross_raw = lv_total_taxable + total_gst_val.
lv_gross     = round( val = lv_gross_raw dec = 0 ).
lv_roundoff  = lv_gross - lv_gross_raw.

value = lv_gross.
CALL METHOD zcl_amttowords=>number2text
  EXPORTING value = value
  RECEIVING text  = DATA(words).

*----------------------------------------------------------------------*
*  Freight / Loading & Unloading / TCS off the pricing conditions
*----------------------------------------------------------------------*
CLEAR: lv_frt_base, lv_frt_cgst, lv_frt_sgst, lv_frt_igst,
       lv_lod_base, lv_lod_cgst, lv_lod_sgst, lv_lod_igst, lv_tcs.

LOOP AT lt_price INTO DATA(ls_cond).
*  IF lr_freight IS NOT INITIAL AND ls_cond-conditiontype IN lr_freight.
  IF  ls_cond-conditiontype  = 'ZFRT'.
    lv_frt_base = lv_frt_base + ls_cond-conditionamount.
*  ELSEIF lr_loading IS NOT INITIAL AND ls_cond-conditiontype IN lr_loading.
  ELSEIF  ls_cond-conditiontype = 'ZLOD'.
    lv_lod_base = lv_lod_base + ls_cond-conditionamount.
*  ELSEIF lr_tcs IS NOT INITIAL AND ls_cond-conditiontype IN lr_tcs.
  ELSEIF  ls_cond-conditiontype = 'JTC1'.
    lv_tcs = lv_tcs + ls_cond-conditionamount.
  ENDIF.
ENDLOOP.

*----------------------------------------------------------------------*
*  TOTAL GROSS AMOUNT = items + freight + loading
*  Grand Total        = gross + TCS
*  TOTAL BILL VALUE   = taxable + CGST + SGST + IGST
*----------------------------------------------------------------------*
lv_frt_cgst = ( lv_frt_base * fright_cgst ) / 100 + ( lv_lod_base * load_cgst ) / 100 .
lv_frt_sgst = ( lv_frt_base * fright_sgst ) / 100 + ( lv_lod_base * load_sgst ) / 100 .
lv_frt_igst = ( lv_frt_base * fright_igst ) / 100 + ( lv_lod_base * load_igst ) / 100 .

lv_tg_amt  = lv_sum_amount    + lv_frt_base + lv_lod_base.
lv_tg_tax  = lv_total_taxable + lv_frt_base + lv_lod_base.
lv_tg_cgst = totcgst     + lv_frt_cgst   + lv_lod_cgst.
lv_tg_sgst = totsgst     + lv_frt_sgst + lv_lod_sgst.
lv_tg_igst = totigst     + lv_frt_igst + lv_lod_igst.
*lv_tg_cgst = cgst_amt_tot     + lv_frt_cgst   + lv_lod_cgst.
*lv_tg_sgst = sgst_amt_tot     + lv_frt_sgst + lv_lod_sgst.
*lv_tg_igst = igst_amt_tot     + lv_frt_igst + lv_lod_igst.

lv_billval = lv_tg_tax + lv_tg_cgst + lv_tg_sgst + lv_tg_igst + lv_tcs.
DATA(lv_billval_1) = round(
    val  = lv_billval
    dec  = 0
).
data roundd type p DECIMALS 2.
roundd = lv_billval_1 - lv_billval.



DATA : Total_tt type p DECIMALS 2,
       Total_fright type  p DECIMALS 2,
       Total_load type  p DECIMALS 2,
       Total_round type  p DECIMALS 2,
       Total_tgm type  p DECIMALS 2,
       Total_tcs type  p DECIMALS 2,
       Total_gt type  p DECIMALS 2.
Total_fright = lv_frt_base + ( ( lv_frt_base * fright_cgst ) / 100 ) + ( ( lv_frt_base * load_igst ) / 100 ) + ( ( lv_lod_base * fright_sgst ) / 100 ) .
Total_load = lv_frt_base + ( lv_lod_base * fright_cgst ) / 100 + ( ( lv_frt_base * load_igst ) / 100 ) + ( ( lv_lod_base * load_sgst ) / 100 )  .
Total_tgm = lv_tg_tax + lv_tg_cgst + lv_tg_sgst + lv_tg_igst .
lv_gt_amt  = lv_tg_amt + lv_tcs  + roundd.
value = lv_billval.
CALL METHOD zcl_amttowords=>number2text
  EXPORTING value = value
  RECEIVING text  = DATA(billwords).


lvxml = lvxml &&
|</ItemTable>| &&
|<TaxSummary>| &&

|<TotalRow>| &&
|<totalamt>{ lv_sum_amount }</totalamt>| &&
|<totaldis>{ lv_sum_discount }</totaldis>| &&
|<totsltaxvalue>{ lv_total_taxable }</totsltaxvalue>| &&
|<totalcgst_p></totalcgst_p>| &&
*|<totalcgstamt>{ cgst_amt_tot }</totalcgstamt>| &&
|<totalcgstamt>{ totcgst }</totalcgstamt>| &&
*|<totalcgstamt>{ cgst_amt_tot }</totalcgstamt>| &&
|<totalsgst></totalsgst>| &&
*|<totalsgstamt>{ sgst_amt_tot }</totalsgstamt>| &&
|<totalsgstamt>{ totsgst }</totalsgstamt>| &&
|<totaligst_p></totaligst_p>| &&
*|<totaligstamt>{ igst_amt_tot }</totaligstamt>| &&
|<totaligstamt>{ totigst }</totaligstamt>| &&
|<Tot0111>{  lv_total_taxable + totcgst + totsgst + totigst }</Tot0111>| &&
|</TotalRow>| &&

|<FreightRow>| &&
|<f_totalamt>{ lv_frt_base }</f_totalamt>| &&
|<Frt0103></Frt0103>| &&
|<f_taxvalue>{ lv_frt_base }</f_taxvalue>| &&
|<freightcgst_p>{ fright_cgst }</freightcgst_p>| &&
|<f_cghtamt>{ ( lv_frt_base * fright_cgst ) / 100 }</f_cghtamt>| &&
*|<f_cghtamt>{ lv_frt_cgst }</f_cghtamt>| &&
|<f_sgst_p>{ fright_sgst }</f_sgst_p>| &&
|<f_sgstamt>{ ( lv_frt_base * fright_sgst ) / 100 }</f_sgstamt>| &&
*|<f_sgstamt>{ lv_frt_sgst }</f_sgstamt>| &&
|<f_ight>{ fright_igst }</f_ight>| &&
*|<f_igstamt>{ lv_frt_igst }</f_igstamt>| &&
|<f_igstamt>{ ( lv_frt_base * fright_igst )  / 100 }</f_igstamt>| &&
|<Frt0111>{ Total_fright }</Frt0111>| &&
|</FreightRow>| &&

|<LoadingRow>| &&
|<l_totalamt>{ lv_lod_base }</l_totalamt>| &&
|<Lod0103></Lod0103>| &&
|<l_taxvalue>{ lv_lod_base }</l_taxvalue>| &&
|<l_cgst_p>{ load_cgst }</l_cgst_p>| &&
|<l_cgstamt>{ ( lv_lod_base * load_cgst ) / 100 }</l_cgstamt>| &&
*|<l_cgstamt>{ lv_lod_cgst }</l_cgstamt>| &&
|<l_sgst_p>{ load_sgst }</l_sgst_p>| &&
|<l_sgstamt>{ ( lv_lod_base * load_sgst ) / 100 }</l_sgstamt>| &&
*|<l_sgstamt>{ lv_lod_sgst }</l_sgstamt>| &&
|<ll_igst>{ load_igst }</ll_igst>| &&
*|<l_igstamt>{ lv_lod_igst }</l_igstamt>| &&
|<l_igstamt>{ ( lv_lod_base * load_igst ) / 100 }</l_igstamt>| &&
|<Lod0111>{ Total_load }</Lod0111>| &&
|</LoadingRow>| &&

|<RoundOffRow>| &&
*|<r_totamt>{ lv_roundoff }</r_totamt>| &&
|<r_totamt>{ roundd }</r_totamt>| &&
|<Rnd0103></Rnd0103>| &&
|<r_taxvalue></r_taxvalue>| &&
|<r_cgst_p></r_cgst_p>| &&
|<r_cgstamt></r_cgstamt>| &&
|<r_sgst_p></r_sgst_p>| &&
|<r_sgstamt></r_sgstamt>| &&
|<r_igst_p></r_igst_p>| &&
|<r_igstamt></r_igstamt>| &&
|<Rnd0111>{ roundd }</Rnd0111>| &&
*|<Rnd0111>{ lv_roundoff }</Rnd0111>| &&
|</RoundOffRow>| &&

|<GrossRow>| &&
|<tg_totamt>{ lv_tg_amt }</tg_totamt>| &&
|<tg_dis>{ lv_sum_discount }</tg_dis>| &&
|<tg__taxvalue>{ lv_tg_tax }</tg__taxvalue>| &&
|<Grs0105></Grs0105>| &&
|<tg__cgstamt>{ lv_tg_cgst }</tg__cgstamt>| &&
|<Grs0107></Grs0107>| &&
|<tg__sgstamt>{ lv_tg_sgst }</tg__sgstamt>| &&
|<Grs0109></Grs0109>| &&
|<tg_igstamt>{ lv_tg_igst }</tg_igstamt>| &&
|<Grs0111></Grs0111>| &&
|</GrossRow>| &&

|<TcsRow>| &&
|<tcs_totamt>{ lv_tcs }</tcs_totamt>| &&
|<Tcs0103></Tcs0103>| &&
|<Tcs0104></Tcs0104>| &&
|<Tcs0105></Tcs0105>| &&
|<Tcs0106></Tcs0106>| &&
|<Tcs0107></Tcs0107>| &&
|<Tcs0108></Tcs0108>| &&
|<Tcs0109></Tcs0109>| &&
|<Tcs0110></Tcs0110>| &&
|<Tcs0111>{ lv_tcs }</Tcs0111>| &&
|</TcsRow>| &&

|<GrandRow>| &&
|<gt_totalamt>{ lv_gt_amt }</gt_totalamt>| &&
|<gt_dis>{ lv_sum_discount }</gt_dis>| &&
|<gt_taxvalue>{ lv_tg_tax }</gt_taxvalue>| &&
|<Grd0105></Grd0105>| &&
|<gt_cgst>{ lv_tg_cgst }</gt_cgst>| &&
|<Grd0107></Grd0107>| &&
|<gt_sgst>{ lv_tg_sgst }</gt_sgst>| &&
|<Grd0109></Grd0109>| &&
|<gt_igst>{ lv_tg_igst }</gt_igst>| &&
|<Grd0111>{ Total_tgm }</Grd0111>| &&
|</GrandRow>| &&

|<BillValueRow>| &&
|<Bill0102></Bill0102>| &&
|<totalbillvalue>{ lv_billval_1 }</totalbillvalue>| &&
|</BillValueRow>| &&

|<BillWordRow>| &&
|<totalbillword>{ billwords }</totalbillword>| &&
|</BillWordRow>| &&

|<CertifiedRow></CertifiedRow>| &&
|</TaxSummary>| &&


|<Footer>| &&
|<FootBox01></FootBox01>| &&
|<FootBox02>| &&
|<TaxAmountInWordsInrTwoLakh>{ words }</TaxAmountInWordsInrTwoLakh>| &&
|</FootBox02>| &&
|<FootBox03></FootBox03>| &&
|<FootBankBox>| &&
|<BankDetails>| &&
|<BankBox01><Paymentdetailsdata></Paymentdetailsdata></BankBox01>| &&
|<BankBox02><Nameofbillerdata>{ wa_head-yy1_namebiller_bdh }</Nameofbillerdata></BankBox02>| &&
|<BankBox03><Banknamedata>{ ls_bank-yy1_bankacccountbn_bdh }</Banknamedata></BankBox03>| &&
|<BankBox04><bankaddressdata>{ bank_add }</bankaddressdata></BankBox04>| &&
|<BankBox05><bankaccnodata>{ ls_bank-yy1_bankacccountbnn_bdh }</bankaccnodata></BankBox05>| &&
|<BankBox06><ifscdata>{ ls_bank-yy1_bankacccountifsc_bdh }</ifscdata></BankBox06>| &&
|</BankDetails>| &&
|<SignatoryArea><SignBox01></SignBox01></SignatoryArea>| &&
|</FootBankBox>| &&
|<TermsBox02></TermsBox02>| &&
|<TermsBox03>| &&
|<Terms0301>{ '1)' && wa_head-yy1_termsandcondition1_bdh }</Terms0301>| &&
|</TermsBox03>| &&
|<TermsBox04>| &&
|<Terms0401>{ '2)' && wa_head-yy1_termsandcondition2_bdh }</Terms0401>| &&
|</TermsBox04>| &&
|<TermsBox05>| &&
|<Terms0501>{ '3)' && wa_head-yy1_termsandcondition3_bdh }</Terms0501>| &&
|</TermsBox05>| &&
|<TermsBox07></TermsBox07>| &&
|<TermsBox08></TermsBox08>| &&
|<TermsBox09></TermsBox09>| &&
|<TermsBox10></TermsBox10>| &&
|<TermsBox11></TermsBox11>| &&
|</Footer>| &&
|</InvoiceBody>| &&
|</form1>|.

REPLACE ALL OCCURRENCES OF '&' IN lvxml WITH '&amp;'.
     TRY.
        DATA(form) = cl_fp_form_reader=>create_form_reader( CONV #( |ZSD_TAXINVOICE| )  ).
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

DATA : it_data TYPE table of ZSD_TAXINVOICE_CDS.

it_data = VALUE #( for LS in IT_ITEM  (

BillingDocument = LS-BillingDocument
PLANT  = ''
BillingType = ''
FileName   = LS-BillingDocument  && '.' && 'PDF'
MimeType  = 'application/pdf'
Form   = pdf
) ).
SORT it_data by BillingDocument.
DELETE ADJACENT DUPLICATES FROM it_data COMPARING BillingDocument.



    io_response->set_data( IT_DATA ).
    io_response->set_total_number_of_records( lines( IT_DATA ) ).

ENDMETHOD.
ENDCLASS.
