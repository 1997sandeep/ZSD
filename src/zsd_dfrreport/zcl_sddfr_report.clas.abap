CLASS zcl_sddfr_report DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.

    TYPES: BEGIN OF ty_line,
             seq            TYPE i,
             rabill         TYPE i_salesorder-purchaseorderbycustomer,
             salesorder     TYPE i_salesorderitem-salesorder,
             salesorderitem TYPE i_salesorderitem-salesorderitem,
             boqsrno        TYPE c LENGTH 40,
             description    TYPE c LENGTH 80,
             unit           TYPE i_billingdocumentitem-baseunit,
             scopeqty       TYPE p LENGTH 13 DECIMALS 3,
             ordqty         TYPE p LENGTH 13 DECIMALS 3,
             balanceqty     TYPE p LENGTH 13 DECIMALS 3,
             rate           TYPE p LENGTH 13 DECIMALS 2,
             amount         TYPE p LENGTH 13 DECIMALS 2,
             soitemnet      TYPE p LENGTH 13 DECIMALS 2,
             prevqty        TYPE p LENGTH 13 DECIMALS 3,
             prevbill       TYPE p LENGTH 13 DECIMALS 2,
             thisqty        TYPE p LENGTH 13 DECIMALS 3,
             thisbill       TYPE p LENGTH 13 DECIMALS 2,
             prevper        TYPE p LENGTH 13 DECIMALS 2,
             thisper        TYPE p LENGTH 13 DECIMALS 2,
             cumper         TYPE p LENGTH 13 DECIMALS 2,
             lastbilldoc    TYPE i_billingdocumentitem-billingdocument,
             lastbillitem   TYPE i_billingdocumentitem-billingdocumentitem,
           END OF ty_line.

    TYPES: BEGIN OF ty_so,
             salesorder              TYPE i_salesorderitem-salesorder,
             purchaseorderbycustomer TYPE i_salesorderitem-purchaseorderbycustomer,
             creationdate            TYPE i_salesorderitem-creationdate,
             soldtoparty             TYPE i_salesorderitem-soldtoparty,
           END OF ty_so.

    TYPES: BEGIN OF ty_soi,
             salesorder              TYPE i_salesorderitem-salesorder,
             salesorderitem          TYPE i_salesorderitem-salesorderitem,
             material                TYPE i_salesorderitem-material,
             product                 TYPE i_salesorderitem-product,
             orderquantity           TYPE i_salesorderitem-orderquantity,
             netamount               TYPE i_salesorderitem-netamount,
             referencesddocument     TYPE i_salesorderitem-referencesddocument,
             referencesddocumentitem TYPE i_salesorderitem-referencesddocumentitem,
           END OF ty_soi.

    TYPES: BEGIN OF ty_bill,
             billingdocument         TYPE i_billingdocumentitem-billingdocument,
             billingdocumentitem     TYPE i_billingdocumentitem-billingdocumentitem,
             referencesddocument     TYPE i_billingdocumentitem-referencesddocument,
             referencesddocumentitem TYPE i_billingdocumentitem-referencesddocumentitem,
             billingquantity         TYPE i_billingdocumentitem-billingquantity,
             baseunit                TYPE i_billingdocumentitem-baseunit,
             netamount               TYPE i_billingdocumentitem-netamount,
             creationdate            TYPE i_billingdocumentitem-creationdate,
           END OF ty_bill.

    DATA it_line TYPE STANDARD TABLE OF ty_line WITH EMPTY KEY.

    DATA it_data TYPE STANDARD TABLE OF zsd_dfr_cds WITH EMPTY KEY.

    DATA lv_contract
      TYPE i_salescontractitem-salescontract.

    DATA lr_so
      TYPE RANGE OF i_salesorderitem-salesorder.

    DATA lr_date
      TYPE RANGE OF datum.

    DATA lr_rabill
      TYPE RANGE OF i_salesorder-purchaseorderbycustomer.

    DATA lv_from TYPE datum.

    DATA lv_to TYPE datum.

    INTERFACES if_rap_query_provider.

  PROTECTED SECTION.

  PRIVATE SECTION.

ENDCLASS.



CLASS ZCL_SDDFR_REPORT IMPLEMENTATION.


  METHOD if_rap_query_provider~select.

    IF NOT io_request->is_data_requested( ).
      RETURN.
    ENDIF.


*---------------------------------------------------------------------*
* Filter Variables
*---------------------------------------------------------------------*

    DATA lv_selected_ra TYPE i.
    DATA lv_ra_low      TYPE string.


*---------------------------------------------------------------------*
* Read Filters
*---------------------------------------------------------------------*

    TRY.

        DATA(lt_filter) =
          io_request->get_filter( )->get_as_ranges( ).

      CATCH cx_rap_query_filter_no_range.

        CLEAR lt_filter.

    ENDTRY.


    LOOP AT lt_filter INTO DATA(ls_filter).

      CASE ls_filter-name.


*---------------------------------------------------------------------*
* Contract Number
*---------------------------------------------------------------------*

        WHEN 'CONTRACTNUMBER'.

          DATA(ls_contract_range) =
            VALUE #( ls_filter-range[ 1 ] OPTIONAL ).

          IF ls_contract_range-low IS NOT INITIAL.

            lv_contract =
              |{ CONV string(
                   ls_contract_range-low ) ALPHA = IN }|.

          ENDIF.


*---------------------------------------------------------------------*
* Sales Order
*---------------------------------------------------------------------*

        WHEN 'SALEORDER'.

          LOOP AT ls_filter-range INTO DATA(ls_so_range).

            IF ls_so_range-low IS NOT INITIAL.

              APPEND VALUE #(
                sign   = 'I'
                option = 'EQ'
                low    = |{ CONV string(
                             ls_so_range-low ) ALPHA = IN }|
              ) TO lr_so.

            ENDIF.

          ENDLOOP.


*---------------------------------------------------------------------*
* RA Bill Number
*---------------------------------------------------------------------*

        WHEN 'RABILLNUMBER'.

          LOOP AT ls_filter-range INTO DATA(ls_ra_range).

            IF ls_ra_range-low IS NOT INITIAL.

              APPEND VALUE #(
                sign   = 'I'
                option = 'EQ'
                low    = ls_ra_range-low
              ) TO lr_rabill.

            ENDIF.

          ENDLOOP.


*---------------------------------------------------------------------*
* Period
*---------------------------------------------------------------------*

        WHEN 'PERIOD'.

          DATA(ls_period_range) =
            VALUE #( ls_filter-range[ 1 ] OPTIONAL ).

          lv_from =
            CONV d( ls_period_range-low ).

          lv_to =
            COND #(
              WHEN ls_period_range-high IS NOT INITIAL
              THEN CONV d( ls_period_range-high )
              ELSE lv_from ).

          IF lv_from IS NOT INITIAL.

            APPEND VALUE #(
              sign   = 'I'
              option = 'BT'
              low    = lv_from
              high   = lv_to
            ) TO lr_date.

          ENDIF.

      ENDCASE.

    ENDLOOP.


*---------------------------------------------------------------------*
* Selected RA Bill
*---------------------------------------------------------------------*

    IF lr_rabill IS NOT INITIAL.

      lv_ra_low =
        CONV string(
          VALUE #( lr_rabill[ 1 ]-low OPTIONAL )
        ).

      TRY.

          lv_selected_ra =
            CONV i( lv_ra_low ).

        CATCH cx_sy_conversion_no_number.

          CLEAR lv_selected_ra.

      ENDTRY.

    ENDIF.


*---------------------------------------------------------------------*
* Contract Number ALPHA
*---------------------------------------------------------------------*

    lv_contract =
      |{ lv_contract ALPHA = IN }|.


*---------------------------------------------------------------------*
* Sales Orders
*---------------------------------------------------------------------*

    DATA lt_so_raw TYPE STANDARD TABLE OF ty_so
                   WITH EMPTY KEY.

    DATA lt_so TYPE STANDARD TABLE OF ty_so
              WITH EMPTY KEY.


*---------------------------------------------------------------------*
* Read Sales Orders Against Contract
*---------------------------------------------------------------------*

    SELECT FROM i_salesorderitem
      FIELDS
        salesorder,
        purchaseorderbycustomer,
        creationdate,
        soldtoparty
      WHERE referencesddocument = @lv_contract
        AND salesorder IN @lr_so
        AND creationdate IN @lr_date
      INTO TABLE @lt_so_raw.


    SORT lt_so_raw BY salesorder.

    DELETE ADJACENT DUPLICATES FROM lt_so_raw
      COMPARING salesorder.

    CLEAR lt_so.


*---------------------------------------------------------------------*
* Select Sales Orders Up To Selected RA
*---------------------------------------------------------------------*

    LOOP AT lt_so_raw INTO DATA(ls_so_raw).

      DATA lv_current_ra TYPE i.

      TRY.

          lv_current_ra =
            CONV i( ls_so_raw-purchaseorderbycustomer ).

        CATCH cx_sy_conversion_no_number.

          CONTINUE.

      ENDTRY.


      IF lv_selected_ra IS INITIAL
         OR lv_current_ra <= lv_selected_ra.

        APPEND ls_so_raw TO lt_so.

      ENDIF.

    ENDLOOP.


    SORT lt_so BY
      creationdate
      purchaseorderbycustomer
      salesorder.


*---------------------------------------------------------------------*
* Sales Order Items
*---------------------------------------------------------------------*

    DATA lt_soi TYPE STANDARD TABLE OF ty_soi
                WITH EMPTY KEY.


    IF lt_so IS NOT INITIAL.

      SELECT FROM i_salesorderitem
        FIELDS
          salesorder,
          salesorderitem,
          material,
          product,
          orderquantity,
          netamount,
          referencesddocument,
          referencesddocumentitem
        FOR ALL ENTRIES IN @lt_so
        WHERE salesorder = @lt_so-salesorder
        INTO TABLE @lt_soi.

    ENDIF.


    SORT lt_soi BY
      salesorder
      salesorderitem.


*---------------------------------------------------------------------*
* Product Description
*---------------------------------------------------------------------*

    SELECT FROM i_productdescription
      FIELDS
        product,
        productdescription
      FOR ALL ENTRIES IN @lt_soi
      WHERE product = @lt_soi-product
        AND language = @sy-langu
      INTO TABLE @DATA(lt_desc).


*---------------------------------------------------------------------*
* Sales Contract Items
*---------------------------------------------------------------------*

    SELECT FROM i_salescontractitem
      FIELDS
        salescontract,
        salescontractitem,
        salescontractitemtext,
        requestedquantity,
        orderquantity
      WHERE salescontract = @lv_contract
      INTO TABLE @DATA(lt_sci).


*---------------------------------------------------------------------*
* Billing Documents
*---------------------------------------------------------------------*

    DATA lt_bill TYPE STANDARD TABLE OF ty_bill
                 WITH EMPTY KEY.


    IF lt_soi IS NOT INITIAL.

      SELECT FROM i_billingdocumentitem
        FIELDS
          billingdocument,
          billingdocumentitem,
          referencesddocument,
          referencesddocumentitem,
          billingquantity,
          baseunit,
          netamount,
          creationdate
        FOR ALL ENTRIES IN @lt_soi
        WHERE referencesddocument = @lt_soi-salesorder
        INTO TABLE @lt_bill.

    ENDIF.


    SORT lt_bill BY
      referencesddocument
      referencesddocumentitem
      creationdate
      billingdocument
      billingdocumentitem.


*---------------------------------------------------------------------*
* RA Bill List
*---------------------------------------------------------------------*

    DATA lt_rabill TYPE stringtab.

    CLEAR lt_rabill.

    DATA lv_seq TYPE i.

    CLEAR lv_seq.


*---------------------------------------------------------------------*
* Build Main Data
*---------------------------------------------------------------------*

    LOOP AT lt_so INTO DATA(ls_so).

      lv_seq =
        lv_seq + 1.


      IF NOT line_exists(
           lt_rabill[
             table_line =
             CONV string(
               ls_so-purchaseorderbycustomer )
           ] ).

        APPEND CONV string(
          ls_so-purchaseorderbycustomer
        ) TO lt_rabill.

      ENDIF.


      LOOP AT lt_soi INTO DATA(ls_soi)
        WHERE salesorder = ls_so-salesorder.


        DATA(ls_line) = VALUE ty_line(

          seq =
            lv_seq

          rabill =
            ls_so-purchaseorderbycustomer

          salesorder =
            ls_soi-salesorder

          salesorderitem =
            ls_soi-salesorderitem

          boqsrno =
            ls_soi-material

          description =
            VALUE #(
              lt_desc[
                product = ls_soi-product
              ]-productdescription OPTIONAL
            )

          scopeqty =
            ls_soi-orderquantity

          ordqty =
            ls_soi-orderquantity

          soitemnet =
            ls_soi-netamount
        ).


*---------------------------------------------------------------------*
* Sales Contract Item
*---------------------------------------------------------------------*

        DATA(ls_sci) =
          VALUE #(
            lt_sci[
              salescontractitem =
                ls_soi-referencesddocumentitem
            ] OPTIONAL
          ).


        IF ls_sci-requestedquantity IS NOT INITIAL.

          ls_line-scopeqty =
            ls_sci-requestedquantity.

          ls_line-balanceqty =
            ls_sci-requestedquantity -
            ls_soi-orderquantity.

        ENDIF.


*---------------------------------------------------------------------*
* Rate
*---------------------------------------------------------------------*

        IF ls_soi-orderquantity IS NOT INITIAL.

          ls_line-rate =
            ls_soi-netamount /
            ls_soi-orderquantity.

        ENDIF.


*---------------------------------------------------------------------*
* Billing Variables
*---------------------------------------------------------------------*

        DATA:

          lv_bill_index
            TYPE i,

          lv_bill_total
            TYPE i,

          lv_so_pricing_amount
            TYPE p LENGTH 13 DECIMALS 2,

          lv_bill_pricing_amount
            TYPE p LENGTH 13 DECIMALS 2,

          lv_bill_percentage
            TYPE p LENGTH 13 DECIMALS 2.


        CLEAR:

          lv_bill_index,

          lv_bill_total,

          lv_so_pricing_amount,

          lv_bill_pricing_amount,

          lv_bill_percentage,

          ls_line-prevqty,

          ls_line-prevbill,

          ls_line-thisqty,

          ls_line-thisbill,

          ls_line-prevper,

          ls_line-thisper,

          ls_line-cumper,

          ls_line-lastbilldoc,

          ls_line-lastbillitem.


*---------------------------------------------------------------------*
* Sales Order Pricing Base
*---------------------------------------------------------------------*

        SELECT SINGLE FROM i_salesorderitempricingelement
          FIELDS
            SUM( conditionamount )
          WHERE salesorder = @ls_soi-salesorder
            AND salesorderitem = @ls_soi-salesorderitem
            AND conditiontype IN
              (
                'ZCON',
                'ZERP',
                'ZCHS'
              )
          INTO @lv_so_pricing_amount.


*---------------------------------------------------------------------*
* Count Billing Documents
*---------------------------------------------------------------------*

        LOOP AT lt_bill INTO DATA(ls_bill_count)
          WHERE referencesddocument =
                  ls_soi-salesorder

            AND referencesddocumentitem =
                  ls_soi-salesorderitem.

          lv_bill_total =
            lv_bill_total + 1.

        ENDLOOP.


*---------------------------------------------------------------------*
* Process Billing Documents
*---------------------------------------------------------------------*

        LOOP AT lt_bill INTO DATA(ls_b)
          WHERE referencesddocument =
                  ls_soi-salesorder

            AND referencesddocumentitem =
                  ls_soi-salesorderitem.


          lv_bill_index =
            lv_bill_index + 1.


          CLEAR:

            lv_bill_pricing_amount,

            lv_bill_percentage.


*---------------------------------------------------------------------*
* Billing Pricing Amount
*---------------------------------------------------------------------*

          SELECT SINGLE FROM i_billingdocumentitemprcgelmnt
            FIELDS
              SUM( conditionamount )
            WHERE billingdocument =
                    @ls_b-billingdocument

              AND billingdocumentitem =
                    @ls_b-billingdocumentitem

              AND conditioncalculationtype =
                    'C'

            INTO @lv_bill_pricing_amount.


*---------------------------------------------------------------------*
* Billing Percentage
*---------------------------------------------------------------------*

          IF lv_so_pricing_amount IS NOT INITIAL.

            lv_bill_percentage =
              ( lv_bill_pricing_amount /
                lv_so_pricing_amount ) * 100.

          ELSE.

            CLEAR lv_bill_percentage.

          ENDIF.


*---------------------------------------------------------------------*
* Previous Billing
*---------------------------------------------------------------------*

          IF lv_bill_index < lv_bill_total.

            ls_line-prevqty =
              ls_line-prevqty +
              ls_b-billingquantity.

            ls_line-prevbill =
              ls_line-prevbill +
              ls_b-netamount.

            ls_line-prevper =
              ls_line-prevper +
              lv_bill_percentage.


*---------------------------------------------------------------------*
* Latest Billing = This Bill
*---------------------------------------------------------------------*

          ELSE.

            ls_line-thisqty =
              ls_b-billingquantity.

            ls_line-thisbill =
              ls_b-netamount.

            ls_line-thisper =
              lv_bill_percentage.

            ls_line-unit =
              ls_b-baseunit.

            ls_line-lastbilldoc =
              ls_b-billingdocument.

            ls_line-lastbillitem =
              ls_b-billingdocumentitem.

          ENDIF.

        ENDLOOP.


*---------------------------------------------------------------------*
* Cumulative Percentage
*---------------------------------------------------------------------*

        ls_line-cumper =
          ls_line-prevper +
          ls_line-thisper.


*---------------------------------------------------------------------*
* Amount
*---------------------------------------------------------------------*

        ls_line-amount =
          ls_line-rate *
          ls_line-thisqty.


        APPEND ls_line TO it_line.

      ENDLOOP.

    ENDLOOP.


*---------------------------------------------------------------------*
* Work
*---------------------------------------------------------------------*

    DATA(lv_work) =
      CONV string(
        VALUE #(
          lt_sci[
            1
          ]-salescontractitemtext OPTIONAL
        )
      ).


*---------------------------------------------------------------------*
* Bill To
*---------------------------------------------------------------------*

    DATA lv_billto TYPE i_customer-customer.


    DATA(lv_firstso) =
      VALUE #(
        lt_so[
          1
        ]-salesorder OPTIONAL
      ).


    SELECT FROM i_salesorderpartner
      FIELDS customer
      WHERE salesorder = @lv_firstso
        AND partnerfunction = 'RE'
      INTO @lv_billto
      UP TO 1 ROWS.

    ENDSELECT.


    IF lv_billto IS INITIAL.

      lv_billto =
        VALUE #(
          lt_so[
            1
          ]-soldtoparty OPTIONAL
        ).

    ENDIF.


*---------------------------------------------------------------------*
* Customer
*---------------------------------------------------------------------*

    DATA:

      lv_client
        TYPE string,

      lv_address
        TYPE string.


    IF lv_billto IS NOT INITIAL.

      SELECT SINGLE FROM i_customer
        FIELDS
          customername,
          bpaddrstreetname,
          bpaddrcityname,
          postalcode,
          country,
          region
        WHERE customer = @lv_billto
        INTO @DATA(ls_cust).


      lv_client =
        ls_cust-customername.


      SELECT SINGLE FROM i_regiontext
        FIELDS regionname
        WHERE country = @ls_cust-country
          AND region = @ls_cust-region
          AND language = @sy-langu
        INTO @DATA(lv_state).


      lv_address =
        ls_cust-bpaddrstreetname.


      IF ls_cust-bpaddrcityname IS NOT INITIAL.

        IF lv_address IS NOT INITIAL.

          lv_address =
            lv_address && `, `.

        ENDIF.

        lv_address =
          lv_address &&
          ls_cust-bpaddrcityname.

      ENDIF.


      IF ls_cust-postalcode IS NOT INITIAL.

        IF lv_address IS NOT INITIAL.

          lv_address =
            lv_address && ` `.

        ENDIF.

        lv_address =
          lv_address &&
          ls_cust-postalcode.

      ENDIF.


      IF lv_state IS NOT INITIAL.

        IF lv_address IS NOT INITIAL.

          lv_address =
            lv_address && ` `.

        ENDIF.

        lv_address =
          lv_address &&
          `(` &&
          lv_state &&
          `)`.

      ENDIF.

    ENDIF.


*---------------------------------------------------------------------*
* XML Variables
*---------------------------------------------------------------------*

    DATA:

      lvxml
        TYPE string,

      lv_taxable
        TYPE p LENGTH 13 DECIMALS 2,

      lv_cgst_r
        TYPE p LENGTH 13 DECIMALS 2,

      lv_sgst_r
        TYPE p LENGTH 13 DECIMALS 2,

      lv_igst_r
        TYPE p LENGTH 13 DECIMALS 2,

      lv_cgst_a
        TYPE p LENGTH 13 DECIMALS 2,

      lv_sgst_a
        TYPE p LENGTH 13 DECIMALS 2,

      lv_igst_a
        TYPE p LENGTH 13 DECIMALS 2,

      lv_gross
        TYPE p LENGTH 13 DECIMALS 2.


*---------------------------------------------------------------------*
* Grand Total Variables (all RA bills) - used for the single footer
*---------------------------------------------------------------------*

    DATA:

      lv_g_taxable
        TYPE p LENGTH 13 DECIMALS 2,

      lv_g_cgst_a
        TYPE p LENGTH 13 DECIMALS 2,

      lv_g_sgst_a
        TYPE p LENGTH 13 DECIMALS 2,

      lv_g_igst_a
        TYPE p LENGTH 13 DECIMALS 2,

      lv_g_gross
        TYPE p LENGTH 13 DECIMALS 2,

      lv_g_cgst_r
        TYPE p LENGTH 13 DECIMALS 2,

      lv_g_sgst_r
        TYPE p LENGTH 13 DECIMALS 2,

      lv_g_igst_r
        TYPE p LENGTH 13 DECIMALS 2.


    DATA:

      lv_prevqty
        TYPE p LENGTH 13 DECIMALS 3,

      lv_prevbill
        TYPE p LENGTH 13 DECIMALS 2,

      lv_totqty
        TYPE p LENGTH 13 DECIMALS 3,

      lv_cumbill
        TYPE p LENGTH 13 DECIMALS 2,

      lv_prevper
        TYPE p LENGTH 13 DECIMALS 2,

      lv_thisper
        TYPE p LENGTH 13 DECIMALS 2,

      lv_cumper
        TYPE p LENGTH 13 DECIMALS 2,

      lv_cumord
        TYPE p LENGTH 13 DECIMALS 3,

      lv_balance
        TYPE p LENGTH 13 DECIMALS 3.


*---------------------------------------------------------------------*
* RA Header
*---------------------------------------------------------------------*

    DATA(lv_ra_hdr) =
      VALUE #(
        lt_rabill[
          lines( lt_rabill )
        ] OPTIONAL
      ).


*---------------------------------------------------------------------*
* Period
*---------------------------------------------------------------------*

    DATA lv_period TYPE string.


    IF lv_from IS NOT INITIAL.

      lv_period =
        |{ lv_from DATE = ENVIRONMENT }|
        &&
        ` to `
        &&
        |{ lv_to DATE = ENVIRONMENT }|.

    ENDIF.


*---------------------------------------------------------------------*
* XML Header
*---------------------------------------------------------------------*

    lvxml =
      |<form1>| &&

      |<DfrBody>| &&

      |<LetterHead01></LetterHead01>| &&

      |<LetterHead02>| &&
      |<Head0201></Head0201>| &&
      |</LetterHead02>| &&

      |<LetterHead03>| &&
      |<NameOfWorkData>{ lv_work }</NameOfWorkData>| &&
      |</LetterHead03>| &&

      |<LetterHead04>| &&
      |<ClientNameData>{ lv_client }</ClientNameData>| &&
      |</LetterHead04>| &&

      |<LetterHead05>| &&
      |<ClientAddressData>{ lv_address }</ClientAddressData>| &&
      |</LetterHead05>| &&

      |<LetterHead06>| &&
      |<RaBillNoData>{ lv_ra_hdr }</RaBillNoData>| &&
      |</LetterHead06>| &&

      |<LetterHead07>| &&
      |<Head0702></Head0702>| &&
      |<PeriodData>{ lv_period }</PeriodData>| &&
      |</LetterHead07>|.


*---------------------------------------------------------------------*
* RA BILL BLOCK
*---------------------------------------------------------------------*

    DATA lv_blk TYPE i.

    CLEAR lv_blk.


    LOOP AT lt_rabill INTO DATA(lv_rabill).

      lv_blk =
        lv_blk + 1.


      CLEAR:

        lv_taxable,

        lv_cgst_r,

        lv_sgst_r,

        lv_igst_r,

        lv_cgst_a,

        lv_sgst_a,

        lv_igst_a,

        lv_gross.


*---------------------------------------------------------------------*
* RA Bill Header
*---------------------------------------------------------------------*

      lvxml =
        lvxml &&

        |<RaBillBlock>| &&

        |<BillHeader>| &&

        |<RaBillTitle>| &&

        |{ `RA Bill Number `
           && |{ lv_blk }|
           && ` - `
           && lv_rabill }| &&

        |</RaBillTitle>| &&

        |</BillHeader>| &&

        |<ItemTable>| &&

        |<ItemRow01></ItemRow01>|.


*---------------------------------------------------------------------*
* RA BILL ITEMS
*---------------------------------------------------------------------*

      LOOP AT it_line INTO DATA(ls_l)
        WHERE rabill = lv_rabill.


        CLEAR:

          lv_prevqty,

          lv_prevbill,

          lv_totqty,

          lv_cumbill,

          lv_prevper,

          lv_thisper,

          lv_cumper,

          lv_cumord,

          lv_balance.


*---------------------------------------------------------------------*
* Previous
*---------------------------------------------------------------------*

        lv_prevqty =
          ls_l-prevqty.

        lv_prevbill =
          ls_l-prevbill.

        lv_prevper =
          ls_l-prevper.


*---------------------------------------------------------------------*
* This
*---------------------------------------------------------------------*

        DATA(lv_thisqty) =
          ls_l-thisqty.

        DATA(lv_thisbill) =
          ls_l-thisbill.


        lv_thisper =
          ls_l-thisper.


*---------------------------------------------------------------------*
* Total Quantity
*---------------------------------------------------------------------*

        lv_totqty =
          lv_prevqty +
          lv_thisqty.


*---------------------------------------------------------------------*
* Cumulative Bill
*---------------------------------------------------------------------*

        lv_cumbill =
          lv_prevbill +
          lv_thisbill.


*---------------------------------------------------------------------*
* Cumulative Order Quantity
*---------------------------------------------------------------------*

        CLEAR lv_cumord.


        LOOP AT it_line INTO DATA(ls_ord)
          WHERE boqsrno = ls_l-boqsrno
            AND seq <= ls_l-seq.

          lv_cumord =
            lv_cumord +
            ls_ord-ordqty.

        ENDLOOP.


*---------------------------------------------------------------------*
* Balance
*---------------------------------------------------------------------*

        lv_balance =
          ls_l-scopeqty -
          lv_cumord.


*---------------------------------------------------------------------*
* Cumulative Percentage
*---------------------------------------------------------------------*

        lv_cumper =
          ls_l-cumper.


*---------------------------------------------------------------------*
* Taxable Value
*---------------------------------------------------------------------*

        lv_taxable =
          lv_taxable +
          lv_thisbill.


*---------------------------------------------------------------------*
* Item XML
*---------------------------------------------------------------------*

        lvxml =
          lvxml &&

          |<ItemRow02>| &&

          |<BoqSrNo>{ ls_l-boqsrno }</BoqSrNo>| &&

          |<Description>{ ls_l-description }</Description>| &&

          |<ScopeQty>{ ls_l-scopeqty }</ScopeQty>| &&

          |<BalanceQty>{ lv_balance }</BalanceQty>| &&

          |<Rate>{ ls_l-rate }</Rate>| &&

          |<Amount>{ ls_l-amount }</Amount>| &&

          |<PrevBillPer>{ lv_prevper }</PrevBillPer>| &&

          |<ThisBillPer>{ lv_thisper }</ThisBillPer>| &&

          |<CumPer>{ lv_cumper }</CumPer>| &&

          |<Unit>{ ls_l-unit }</Unit>| &&

          |<PrevQty>{ lv_prevqty }</PrevQty>| &&

          |<ThisQty>{ lv_thisqty }</ThisQty>| &&

          |<TotalQty>{ lv_totqty }</TotalQty>| &&

          |<PrevBill>{ lv_prevbill }</PrevBill>| &&

          |<ThisBill>{ lv_thisbill }</ThisBill>| &&

          |<CumBill>{ lv_cumbill }</CumBill>| &&

          |</ItemRow02>|.


*---------------------------------------------------------------------*
* GST Rate
*---------------------------------------------------------------------*

        IF ls_l-lastbilldoc IS NOT INITIAL

           AND lv_cgst_r IS INITIAL

           AND lv_sgst_r IS INITIAL

           AND lv_igst_r IS INITIAL.


          SELECT FROM i_billingdocitemprcgelmntbasic

            FIELDS
              conditiontype,
              conditionratevalue

            WHERE billingdocument =
                    @ls_l-lastbilldoc

              AND billingdocumentitem =
                    @ls_l-lastbillitem

              AND conditiontype IN
                    (
                      'JOCG',
                      'JOSG',
                      'JOIG'
                    )

            INTO TABLE @DATA(lt_gst).


          LOOP AT lt_gst INTO DATA(ls_g).

            CASE ls_g-conditiontype.

              WHEN 'JOCG'.

                lv_cgst_r =
                  ls_g-conditionratevalue.

              WHEN 'JOSG'.

                lv_sgst_r =
                  ls_g-conditionratevalue.

              WHEN 'JOIG'.

                lv_igst_r =
                  ls_g-conditionratevalue.

            ENDCASE.

          ENDLOOP.

        ENDIF.

      ENDLOOP.


*---------------------------------------------------------------------*
* GST AMOUNT (for this RA bill)
*---------------------------------------------------------------------*

      lv_cgst_a =
        lv_taxable *
        lv_cgst_r /
        100.


      lv_sgst_a =
        lv_taxable *
        lv_sgst_r /
        100.


      lv_igst_a =
        lv_taxable *
        lv_igst_r /
        100.


*---------------------------------------------------------------------*
* Gross Amount (for this RA bill)
*---------------------------------------------------------------------*

      lv_gross =
        lv_taxable +
        lv_cgst_a +
        lv_sgst_a +
        lv_igst_a.


*---------------------------------------------------------------------*
* Accumulate Grand Totals (all RA bills)
*---------------------------------------------------------------------*

      lv_g_taxable = lv_g_taxable + lv_taxable.
      lv_g_cgst_a  = lv_g_cgst_a  + lv_cgst_a.
      lv_g_sgst_a  = lv_g_sgst_a  + lv_sgst_a.
      lv_g_igst_a  = lv_g_igst_a  + lv_igst_a.
      lv_g_gross   = lv_g_gross   + lv_gross.

      " keep the latest non-zero rate for display
      IF lv_cgst_r IS NOT INITIAL.
        lv_g_cgst_r = lv_cgst_r.
      ENDIF.

      IF lv_sgst_r IS NOT INITIAL.
        lv_g_sgst_r = lv_sgst_r.
      ENDIF.

      IF lv_igst_r IS NOT INITIAL.
        lv_g_igst_r = lv_igst_r.
      ENDIF.


*---------------------------------------------------------------------*
* Close Item Table, Spacer and RA Bill Block
* (Tax summary / footer are NOT written here anymore)
*---------------------------------------------------------------------*

      lvxml =
        lvxml &&

        |</ItemTable>| &&
        |</RaBillBlock>|.


*---------------------------------------------------------------------*
* TAX SUMMARY + FOOTER - only inside the LAST RA bill block,
* with the sum of all RA bills
*---------------------------------------------------------------------*

      IF lv_blk = lines( lt_rabill ).

      lvxml =
        lvxml &&

        |<TaxSummary>| &&

        |<TaxRow01>| &&

        |<TaxableValueData>{ lv_g_taxable }</TaxableValueData>| &&

        |</TaxRow01>| &&

        |<TaxRow02></TaxRow02>| &&

        |<TaxRow03>| &&

        |<CgstRate>{ lv_g_cgst_r }</CgstRate>| &&

        |<CgstAmt>{ lv_g_cgst_a }</CgstAmt>| &&

        |</TaxRow03>| &&

        |<TaxRow04>| &&

        |<SgstRate>{ lv_g_sgst_r }</SgstRate>| &&

        |<SgstAmt>{ lv_g_sgst_a }</SgstAmt>| &&

        |</TaxRow04>| &&

        |<TaxRow05>| &&

        |<IgstRate>{ lv_g_igst_r }</IgstRate>| &&

        |<IgstAmt>{ lv_g_igst_a }</IgstAmt>| &&

        |</TaxRow05>| &&

        |<TaxRow06>| &&

        |<GrossAmt>{ lv_g_gross }</GrossAmt>| &&

        |</TaxRow06>| &&

*        |</TaxSummary>| &&
        |</TaxSummary>| .

*        |<RaBillFooter>| &&
*
*        |<FooterTitle>TOTAL (ALL RA BILLS)</FooterTitle>| &&
*
*        |<FooterRow>| &&
*
*        |<FooterTaxable>{ lv_g_taxable }</FooterTaxable>| &&
*
*        |<FooterCGSTRate>{ lv_g_cgst_r }</FooterCGSTRate>| &&
*
*        |<FooterCGSTAmount>{ lv_g_cgst_a }</FooterCGSTAmount>| &&
*
*        |<FooterSGSTRate>{ lv_g_sgst_r }</FooterSGSTRate>| &&
*
*        |<FooterSGSTAmount>{ lv_g_sgst_a }</FooterSGSTAmount>| &&
*
*        |<FooterIGSTRate>{ lv_g_igst_r }</FooterIGSTRate>| &&
*
*        |<FooterIGSTAmount>{ lv_g_igst_a }</FooterIGSTAmount>| &&
*
*        |<FooterGross>{ lv_g_gross }</FooterGross>| &&
*
*        |</FooterRow>| &&

*        |</RaBillFooter>|.

      ENDIF.


      lvxml =
        lvxml &&

*        |<BlockSpacer>| &&

        |<Spacer0101></Spacer0101>| .

*        |</BlockSpacer>| &&
*
*        |</RaBillBlock>|.
*        |</BlockSpacer>| &&
*
*        |</RaBillBlock>|.


*---------------------------------------------------------------------*
* END RA BILL
*---------------------------------------------------------------------*

    ENDLOOP.


*---------------------------------------------------------------------*
* Close XML
*---------------------------------------------------------------------*

    lvxml =
      lvxml &&

      |</DfrBody>| &&

      |</form1>|.


*---------------------------------------------------------------------*
* XML Special Character
*---------------------------------------------------------------------*

    REPLACE ALL OCCURRENCES OF '&'
      IN lvxml
      WITH '&amp;'.


    REPLACE ALL OCCURRENCES OF 'Ø'
      IN lvxml
      WITH ' '.


*---------------------------------------------------------------------*
* Render PDF
*---------------------------------------------------------------------*

    DATA pdf TYPE xstring.


    TRY.

        DATA(form) =
          cl_fp_form_reader=>create_form_reader(
            CONV #(
              |ZSD_DFR_FORM|
            )
          ).


        cl_fp_ads_util=>render_pdf(

          EXPORTING

            iv_locale =
              'en_US'

            iv_xdp_layout =
              form->get_layout( )

            iv_xml_data =
              xco_cp=>string(
                cl_web_http_utility=>encode_base64(
                  lvxml
                )
              )->as_xstring(

                xco_cp_binary=>text_encoding->base64

              )->value

            is_options =
              VALUE #(
                trace_level =
                  0

                embed_fonts =
                  form->get_font_embed( )
              )

          IMPORTING

            ev_pdf =
              pdf

            ev_trace_string =
              DATA(logs)
        ).


      CATCH cx_fp_ads_util
            cx_fp_form_reader.

        CLEAR pdf.

    ENDTRY.


*---------------------------------------------------------------------*
* Return PDF
*---------------------------------------------------------------------*

    IF pdf IS NOT INITIAL.

      it_data =
        VALUE #(
          (
            contractnumber =
              lv_contract

            saleorder =
              VALUE #(
                lt_so[
                  1
                ]-salesorder OPTIONAL
              )

            rabillnumber =
              lv_ra_hdr

            period =
              ''

            filename =
              |DFR_{ lv_contract ALPHA = OUT }.PDF|

            mimetype =
              'application/pdf'

            form =
              pdf
          )
        ).

    ENDIF.


*---------------------------------------------------------------------*
* Total Records
*---------------------------------------------------------------------*

    IF io_request->is_total_numb_of_rec_requested( ).

      io_response->set_total_number_of_records(
        lines( it_data )
      ).

    ENDIF.


*---------------------------------------------------------------------*
* Set Data
*---------------------------------------------------------------------*

    IF io_request->is_data_requested( ).

      io_response->set_data(
        it_data
      ).

    ENDIF.

  ENDMETHOD.
ENDCLASS.
