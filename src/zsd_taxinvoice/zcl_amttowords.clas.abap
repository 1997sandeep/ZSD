CLASS zcl_amttowords DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    INTERFACES if_oo_adt_classrun.

    CLASS-METHODS number2text IMPORTING value       TYPE string
                               RETURNING VALUE(text) TYPE string.
    CLASS-METHODS convert_number IMPORTING number      TYPE string
                                    RETURNING VALUE(text) TYPE string.
    CLASS-METHODS get_number_text IMPORTING number      TYPE string
                                  RETURNING VALUE(text) TYPE string.
  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS ZCL_AMTTOWORDS IMPLEMENTATION.


  METHOD convert_number.
    CONSTANTS: BEGIN OF lc,
                 crores    TYPE i VALUE 10000000,
                 lakhs     TYPE i VALUE 100000,
                 thousands TYPE i VALUE 1000,
                 hundreds  TYPE i VALUE 100,
               END OF lc.

    DATA: lv_crores    TYPE string,
          lv_lakhs     TYPE string,
          lv_thousands TYPE string,
          lv_hundreds  TYPE string,
          lv_tens      TYPE string,
          lv_units     TYPE string,
          lv_10        TYPE string,
          temp_text    TYPE string,
          number_1     TYPE p.

    IF number < 0 OR number > 999999999.
      text = 'NUMBER OUT OF RANGE!'.
      RETURN.
    ENDIF.

    lv_crores = number DIV lc-crores.
    number_1 = number.
    number_1 = number MOD lc-crores.

    lv_lakhs = number DIV lc-lakhs.
    number_1 = number.
    number_1 = number MOD lc-lakhs.

    lv_thousands = number DIV lc-thousands.
    number_1 = number.
    number_1 = number MOD lc-thousands.

    lv_hundreds = number DIV lc-hundreds.
    number_1 = number.
    number_1 = number MOD lc-hundreds.
    lv_10 = 10.
    lv_tens = number DIV 10.
    lv_units = number MOD 10.

    IF lv_crores > 0.
      temp_text = convert_number( lv_crores ).
      CONCATENATE temp_text 'CRORE' INTO text SEPARATED BY space.
    ENDIF.

    IF lv_lakhs > 0.
      temp_text = convert_number( lv_lakhs ).
      CONCATENATE text temp_text 'LAKH' INTO text SEPARATED BY space.
    ENDIF.

    IF lv_thousands > 0.
      temp_text = convert_number( lv_thousands ).
      CONCATENATE text temp_text 'THOUSAND' INTO text SEPARATED BY space.
    ENDIF.

    IF lv_hundreds > 0.
      temp_text = convert_number( lv_hundreds ).
      CONCATENATE text temp_text 'HUNDRED' INTO text SEPARATED BY space.
    ENDIF.

    IF lv_tens > 0 OR lv_units > 0.
      IF text IS NOT INITIAL.
        CONCATENATE text 'AND' INTO text SEPARATED BY space.
      ENDIF.

      IF lv_tens < 2.
        DATA: lv_combined TYPE string.
        lv_combined = lv_tens * 10 + lv_units.
        temp_text = get_number_text( lv_combined ).
        CONCATENATE text temp_text INTO text SEPARATED BY space.
      ELSE.
        temp_text = get_number_text( lv_tens )  * lv_10 .
        CONCATENATE text temp_text INTO text SEPARATED BY space.

        IF lv_units > 0.
          temp_text = get_number_text( lv_units ).
          CONCATENATE text '-' temp_text INTO text SEPARATED BY space.
        ENDIF.
      ENDIF.
    ENDIF.

    IF text IS INITIAL.
      text = 'ZERO'.
    ENDIF.
  ENDMETHOD.


  METHOD get_number_text.
    DATA: lc_ones TYPE TABLE OF string WITH EMPTY KEY,
          lc_tens TYPE TABLE OF string WITH EMPTY KEY.

    APPEND 'ZERO' TO lc_ones.
    APPEND 'ONE' TO lc_ones.
    APPEND 'TWO' TO lc_ones.
    APPEND 'THREE' TO lc_ones.
    APPEND 'FOUR' TO lc_ones.
    APPEND 'FIVE' TO lc_ones.
    APPEND 'SIX' TO lc_ones.
    APPEND 'SEVEN' TO lc_ones.
    APPEND 'EIGHT' TO lc_ones.
    APPEND 'NINE' TO lc_ones.
    APPEND 'TEN' TO lc_ones.
    APPEND 'ELEVEN' TO lc_ones.
    APPEND 'TWELVE' TO lc_ones.
    APPEND 'THIRTEEN' TO lc_ones.
    APPEND 'FOURTEEN' TO lc_ones.
    APPEND 'FIFTEEN' TO lc_ones.
    APPEND 'SIXTEEN' TO lc_ones.
    APPEND 'SEVENTEEN' TO lc_ones.
    APPEND 'EIGHTEEN' TO lc_ones.
    APPEND 'NINETEEN' TO lc_ones.

    APPEND '' TO lc_tens.
    APPEND '' TO lc_tens.
    APPEND 'TWENTY' TO lc_tens.
    APPEND 'THIRTY' TO lc_tens.
    APPEND 'FORTY' TO lc_tens.
    APPEND 'FIFTY' TO lc_tens.
    APPEND 'SIXTY' TO lc_tens.
    APPEND 'SEVENTY' TO lc_tens.
    APPEND 'EIGHTY' TO lc_tens.
    APPEND 'NINETY' TO lc_tens.

    DATA: lv_number TYPE i VALUE 45,
          lv_text   TYPE string.

    FIELD-SYMBOLS: <fs_one> TYPE string,
                   <fs_ten> TYPE string.

* Function to convert numbers to words
    IF lv_number < 20.
      READ TABLE lc_ones INDEX lv_number + 1 INTO lv_text.
    ELSE.
      READ TABLE lc_tens INDEX ( lv_number / 10 ) + 1 INTO lv_text.
      IF lv_number MOD 10 > 0.
        READ TABLE lc_ones INDEX ( lv_number MOD 10 ) + 1 INTO DATA(lv_one_text).
        CONCATENATE lv_text '-' lv_one_text INTO lv_text.
      ENDIF.
    ENDIF.
  ENDMETHOD.


  METHOD if_oo_adt_classrun~main.

  ENDMETHOD.


  METHOD number2text.
**    DATA: fraction      TYPE string,
**          fraction_text TYPE string,
**          integer_text  TYPE string,
**          integer_value TYPE string.
**
**    integer_value = value DIV 1.
**    fraction = ( value - integer_value ) * 100.
**
**    IF fraction > 0.
**      fraction_text = get_number_text( fraction ).
**      CONCATENATE 'AND' fraction_text 'PAISE' INTO fraction_text SEPARATED BY space.
**    ENDIF.
**
**    integer_text = convert_number( integer_value ).
**
**    CONCATENATE integer_text 'RUPEE' fraction_text 'ONLY' INTO text SEPARATED BY space.

"""""""""""" Start : Convert Amount to Word """"""""""""""""""
data :  AMT_IN_NUM   TYPE  p DECIMALS 2,
        AMT_IN_WORDS(100) TYPE  C.

   AMT_IN_NUM = value.

  DATA: MAXNO TYPE P.
  MAXNO = 10 ** 9.
  IF ( AMT_IN_NUM >= MAXNO ).
*    RAISE DATA_TYPE_MISMATCH.
  ENDIF.
*data declaration-------------------------------------------------*
  DATA: TEN(10),SINGLE(6),FINAL(130),DEC(20),RES TYPE I,RP(7).
  DATA: A1 TYPE I,A2 TYPE I,STR(20),D TYPE P,M TYPE I,WRDREP(20).
  DATA: CNTR TYPE I,F1 TYPE I,F2 TYPE I,F3 TYPE I,F4 TYPE I,F5 TYPE I.
  DATA: F6 TYPE I,F7 TYPE I,F8 TYPE I,F9 TYPE I.

  D = ( AMT_IN_NUM * 100 ) DIV 100.
  RES = ( AMT_IN_NUM * 100 ) MOD 100.

  F1 = RES DIV 10.
  F2 = RES MOD 10.
""  PERFORM SETNUM USING F1 F2 CHANGING WRDREP.
"""""" Perform Code """"""""""""
  clear : A1,A2,WRDREP.
  A1 = F1.
  A2 = F2.

  TEN = ''.SINGLE = ''.
  IF ( A1 = 1 ).

    CASE A2.
      WHEN 0. TEN = 'TEN'.
      WHEN 1. TEN = 'ELEVEN'.
      WHEN 2. TEN = 'TWELVE'.
      WHEN 3. TEN = 'THIRTEEN'.
      WHEN 4. TEN = 'FOURTEEN'.
      WHEN 5. TEN = 'FIFTEEN'.
      WHEN 6. TEN = 'SIXTEEN'.
      WHEN 7. TEN = 'SEVENTEEN'.
      WHEN 8. TEN = 'EIGHTEEN'.
      WHEN 9. TEN = 'NINETEEN'.
    ENDCASE.
  ELSE.

    CASE A2.
      WHEN 1. SINGLE = 'ONE'.
      WHEN 2. SINGLE = 'TWO'.
      WHEN 3. SINGLE = 'THREE'.
      WHEN 4. SINGLE = 'FOUR'.
      WHEN 5. SINGLE = 'FIVE'.
      WHEN 6. SINGLE = 'SIX'.
      WHEN 7. SINGLE = 'SEVEN'.
      WHEN 8. SINGLE = 'EIGHT'.
      WHEN 9. SINGLE = 'NINE'.
    ENDCASE.
    CASE A1.
      WHEN 2. TEN = 'TWENTY'.
      WHEN 3. TEN = 'THIRTY'.
      WHEN 4. TEN = 'FORTY'.
      WHEN 5. TEN = 'FIFTY'.
      WHEN 6. TEN = 'SIXTY'.
      WHEN 7. TEN = 'SEVENTY'.
      WHEN 8. TEN = 'EIGHTY'.
      WHEN 9. TEN = 'NINETY'.
    ENDCASE.

  ENDIF.
  IF ( SINGLE <> '' ) AND ( TEN <> '' ).
    CONCATENATE TEN SINGLE INTO STR SEPARATED BY ' '.
  ELSEIF SINGLE = ''.
    STR = TEN.
  ELSE.
    STR = SINGLE.
  ENDIF.
  WRDREP = STR.
"""""" End:Perform Code """"""""""""

  F1 = 0. F2 = 0.
  DEC = WRDREP.
  CNTR = 1.
*Go in a loop dividing the numbers by 10 and store the
*residues as a digit in f1 .... f9
  WHILE ( D > 0 ).
    M = D MOD 10.
    D = D DIV 10.
    CASE CNTR.
      WHEN 1. F1 = M.
      WHEN 2. F2 = M.
      WHEN 3. F3 = M.
      WHEN 4. F4 = M.
      WHEN 5. F5 = M.
      WHEN 6. F6 = M.
      WHEN 7. F7 = M.
      WHEN 8. F8 = M.
      WHEN 9. F9 = M.
    ENDCASE.
    CNTR = CNTR + 1.
  ENDWHILE.
  CNTR = CNTR - 1.
*Going in loop and sending pair of digits to function setnum to get
*the standing value of digits in words
  WHILE ( CNTR > 0 ).

    IF ( CNTR <= 2 ).
""      PERFORM SETNUM USING F2 F1 CHANGING WRDREP.

"""""" Perform Code """"""""""""
  clear : A1,A2,WRDREP.
  A1 = F2.
  A2 = F1.

  TEN = ''.SINGLE = ''.
  IF ( A1 = 1 ).

    CASE A2.
      WHEN 0. TEN = 'TEN'.
      WHEN 1. TEN = 'ELEVEN'.
      WHEN 2. TEN = 'TWELVE'.
      WHEN 3. TEN = 'THIRTEEN'.
      WHEN 4. TEN = 'FOURTEEN'.
      WHEN 5. TEN = 'FIFTEEN'.
      WHEN 6. TEN = 'SIXTEEN'.
      WHEN 7. TEN = 'SEVENTEEN'.
      WHEN 8. TEN = 'EIGHTEEN'.
      WHEN 9. TEN = 'NINETEEN'.
    ENDCASE.
  ELSE.

    CASE A2.
      WHEN 1. SINGLE = 'ONE'.
      WHEN 2. SINGLE = 'TWO'.
      WHEN 3. SINGLE = 'THREE'.
      WHEN 4. SINGLE = 'FOUR'.
      WHEN 5. SINGLE = 'FIVE'.
      WHEN 6. SINGLE = 'SIX'.
      WHEN 7. SINGLE = 'SEVEN'.
      WHEN 8. SINGLE = 'EIGHT'.
      WHEN 9. SINGLE = 'NINE'.
    ENDCASE.
    CASE A1.
      WHEN 2. TEN = 'TWENTY'.
      WHEN 3. TEN = 'THIRTY'.
      WHEN 4. TEN = 'FORTY'.
      WHEN 5. TEN = 'FIFTY'.
      WHEN 6. TEN = 'SIXTY'.
      WHEN 7. TEN = 'SEVENTY'.
      WHEN 8. TEN = 'EIGHTY'.
      WHEN 9. TEN = 'NINETY'.
    ENDCASE.

  ENDIF.
  IF ( SINGLE <> '' ) AND ( TEN <> '' ).
    CONCATENATE TEN SINGLE INTO STR SEPARATED BY ' '.
  ELSEIF SINGLE = ''.
    STR = TEN.
  ELSE.
    STR = SINGLE.
  ENDIF.
  WRDREP = STR.
"""""" End:Perform Code """"""""""""

      CONCATENATE FINAL WRDREP INTO FINAL SEPARATED BY ' '.
    ELSEIF ( CNTR = 3 ).
      IF ( F3 <> 0 ).
**        PERFORM SETNUM USING 0 F3 CHANGING WRDREP.
"""""" Perform Code """"""""""""
  clear : A1,A2,WRDREP.
  A1 = 0.
  A2 = F3.

  TEN = ''.SINGLE = ''.
  IF ( A1 = 1 ).

    CASE A2.
      WHEN 0. TEN = 'TEN'.
      WHEN 1. TEN = 'ELEVEN'.
      WHEN 2. TEN = 'TWELVE'.
      WHEN 3. TEN = 'THIRTEEN'.
      WHEN 4. TEN = 'FOURTEEN'.
      WHEN 5. TEN = 'FIFTEEN'.
      WHEN 6. TEN = 'SIXTEEN'.
      WHEN 7. TEN = 'SEVENTEEN'.
      WHEN 8. TEN = 'EIGHTEEN'.
      WHEN 9. TEN = 'NINETEEN'.
    ENDCASE.
  ELSE.

    CASE A2.
      WHEN 1. SINGLE = 'ONE'.
      WHEN 2. SINGLE = 'TWO'.
      WHEN 3. SINGLE = 'THREE'.
      WHEN 4. SINGLE = 'FOUR'.
      WHEN 5. SINGLE = 'FIVE'.
      WHEN 6. SINGLE = 'SIX'.
      WHEN 7. SINGLE = 'SEVEN'.
      WHEN 8. SINGLE = 'EIGHT'.
      WHEN 9. SINGLE = 'NINE'.
    ENDCASE.
    CASE A1.
      WHEN 2. TEN = 'TWENTY'.
      WHEN 3. TEN = 'THIRTY'.
      WHEN 4. TEN = 'FORTY'.
      WHEN 5. TEN = 'FIFTY'.
      WHEN 6. TEN = 'SIXTY'.
      WHEN 7. TEN = 'SEVENTY'.
      WHEN 8. TEN = 'EIGHTY'.
      WHEN 9. TEN = 'NINETY'.
    ENDCASE.

  ENDIF.
  IF ( SINGLE <> '' ) AND ( TEN <> '' ).
    CONCATENATE TEN SINGLE INTO STR SEPARATED BY ' '.
  ELSEIF SINGLE = ''.
    STR = TEN.
  ELSE.
    STR = SINGLE.
  ENDIF.
  WRDREP = STR.
"""""" End:Perform Code """"""""""""

        CONCATENATE FINAL WRDREP 'HUNDRED' INTO FINAL SEPARATED BY ' '.
      ENDIF.
    ELSEIF ( CNTR <= 5 ).
      IF ( F5 <> 0 ) OR ( F4 <> 0 ).
**        PERFORM SETNUM USING F5 F4 CHANGING WRDREP.
"""""" Perform Code """"""""""""
  clear : A1,A2,WRDREP.
  A1 = F5.
  A2 = F4.

  TEN = ''.SINGLE = ''.
  IF ( A1 = 1 ).

    CASE A2.
      WHEN 0. TEN = 'TEN'.
      WHEN 1. TEN = 'ELEVEN'.
      WHEN 2. TEN = 'TWELVE'.
      WHEN 3. TEN = 'THIRTEEN'.
      WHEN 4. TEN = 'FOURTEEN'.
      WHEN 5. TEN = 'FIFTEEN'.
      WHEN 6. TEN = 'SIXTEEN'.
      WHEN 7. TEN = 'SEVENTEEN'.
      WHEN 8. TEN = 'EIGHTEEN'.
      WHEN 9. TEN = 'NINETEEN'.
    ENDCASE.
  ELSE.

    CASE A2.
      WHEN 1. SINGLE = 'ONE'.
      WHEN 2. SINGLE = 'TWO'.
      WHEN 3. SINGLE = 'THREE'.
      WHEN 4. SINGLE = 'FOUR'.
      WHEN 5. SINGLE = 'FIVE'.
      WHEN 6. SINGLE = 'SIX'.
      WHEN 7. SINGLE = 'SEVEN'.
      WHEN 8. SINGLE = 'EIGHT'.
      WHEN 9. SINGLE = 'NINE'.
    ENDCASE.
    CASE A1.
      WHEN 2. TEN = 'TWENTY'.
      WHEN 3. TEN = 'THIRTY'.
      WHEN 4. TEN = 'FORTY'.
      WHEN 5. TEN = 'FIFTY'.
      WHEN 6. TEN = 'SIXTY'.
      WHEN 7. TEN = 'SEVENTY'.
      WHEN 8. TEN = 'EIGHTY'.
      WHEN 9. TEN = 'NINETY'.
    ENDCASE.

  ENDIF.
  IF ( SINGLE <> '' ) AND ( TEN <> '' ).
    CONCATENATE TEN SINGLE INTO STR SEPARATED BY ' '.
  ELSEIF SINGLE = ''.
    STR = TEN.
  ELSE.
    STR = SINGLE.
  ENDIF.
  WRDREP = STR.
"""""" End:Perform Code """"""""""""

        CONCATENATE FINAL WRDREP 'THOUSAND' INTO FINAL SEPARATED BY ' '
  .
      ENDIF.
      IF ( CNTR = 4 ).
        CNTR = 5.
      ENDIF.
    ELSEIF ( CNTR <= 7 ).
      IF ( F7 <> 0 ) OR ( F6 <> 0 ).
""        PERFORM SETNUM USING F7 F6 CHANGING WRDREP.
"""""" Perform Code """"""""""""
  clear : A1,A2,WRDREP.
  A1 = F7.
  A2 = F6.

  TEN = ''.SINGLE = ''.
  IF ( A1 = 1 ).

    CASE A2.
      WHEN 0. TEN = 'TEN'.
      WHEN 1. TEN = 'ELEVEN'.
      WHEN 2. TEN = 'TWELVE'.
      WHEN 3. TEN = 'THIRTEEN'.
      WHEN 4. TEN = 'FOURTEEN'.
      WHEN 5. TEN = 'FIFTEEN'.
      WHEN 6. TEN = 'SIXTEEN'.
      WHEN 7. TEN = 'SEVENTEEN'.
      WHEN 8. TEN = 'EIGHTEEN'.
      WHEN 9. TEN = 'NINETEEN'.
    ENDCASE.
  ELSE.

    CASE A2.
      WHEN 1. SINGLE = 'ONE'.
      WHEN 2. SINGLE = 'TWO'.
      WHEN 3. SINGLE = 'THREE'.
      WHEN 4. SINGLE = 'FOUR'.
      WHEN 5. SINGLE = 'FIVE'.
      WHEN 6. SINGLE = 'SIX'.
      WHEN 7. SINGLE = 'SEVEN'.
      WHEN 8. SINGLE = 'EIGHT'.
      WHEN 9. SINGLE = 'NINE'.
    ENDCASE.
    CASE A1.
      WHEN 2. TEN = 'TWENTY'.
      WHEN 3. TEN = 'THIRTY'.
      WHEN 4. TEN = 'FORTY'.
      WHEN 5. TEN = 'FIFTY'.
      WHEN 6. TEN = 'SIXTY'.
      WHEN 7. TEN = 'SEVENTY'.
      WHEN 8. TEN = 'EIGHTY'.
      WHEN 9. TEN = 'NINETY'.
    ENDCASE.

  ENDIF.
  IF ( SINGLE <> '' ) AND ( TEN <> '' ).
    CONCATENATE TEN SINGLE INTO STR SEPARATED BY ' '.
  ELSEIF SINGLE = ''.
    STR = TEN.
  ELSE.
    STR = SINGLE.
  ENDIF.
  WRDREP = STR.
"""""" End:Perform Code """"""""""""

        CONCATENATE FINAL WRDREP 'LAKH' INTO FINAL SEPARATED BY ' ' .
      ENDIF.
    ELSEIF ( CNTR <= 9 ).
**      PERFORM SETNUM USING F9 F8 CHANGING WRDREP.
"""""" Perform Code """"""""""""
  clear : A1,A2,WRDREP.
  A1 = F9.
  A2 = F8.

  TEN = ''.SINGLE = ''.
  IF ( A1 = 1 ).

    CASE A2.
      WHEN 0. TEN = 'TEN'.
      WHEN 1. TEN = 'ELEVEN'.
      WHEN 2. TEN = 'TWELVE'.
      WHEN 3. TEN = 'THIRTEEN'.
      WHEN 4. TEN = 'FOURTEEN'.
      WHEN 5. TEN = 'FIFTEEN'.
      WHEN 6. TEN = 'SIXTEEN'.
      WHEN 7. TEN = 'SEVENTEEN'.
      WHEN 8. TEN = 'EIGHTEEN'.
      WHEN 9. TEN = 'NINETEEN'.
    ENDCASE.
  ELSE.

    CASE A2.
      WHEN 1. SINGLE = 'ONE'.
      WHEN 2. SINGLE = 'TWO'.
      WHEN 3. SINGLE = 'THREE'.
      WHEN 4. SINGLE = 'FOUR'.
      WHEN 5. SINGLE = 'FIVE'.
      WHEN 6. SINGLE = 'SIX'.
      WHEN 7. SINGLE = 'SEVEN'.
      WHEN 8. SINGLE = 'EIGHT'.
      WHEN 9. SINGLE = 'NINE'.
    ENDCASE.
    CASE A1.
      WHEN 2. TEN = 'TWENTY'.
      WHEN 3. TEN = 'THIRTY'.
      WHEN 4. TEN = 'FORTY'.
      WHEN 5. TEN = 'FIFTY'.
      WHEN 6. TEN = 'SIXTY'.
      WHEN 7. TEN = 'SEVENTY'.
      WHEN 8. TEN = 'EIGHTY'.
      WHEN 9. TEN = 'NINETY'.
    ENDCASE.

  ENDIF.
  IF ( SINGLE <> '' ) AND ( TEN <> '' ).
    CONCATENATE TEN SINGLE INTO STR SEPARATED BY ' '.
  ELSEIF SINGLE = ''.
    STR = TEN.
  ELSE.
    STR = SINGLE.
  ENDIF.
  WRDREP = STR.
"""""" End:Perform Code """"""""""""

      CONCATENATE FINAL WRDREP 'CRORE' INTO FINAL SEPARATED BY ' ' .
    ENDIF.

    CNTR = CNTR - 2.
  ENDWHILE.
*Output the final
  IF ( FINAL = ' ONE' ).RP = 'RUPEE'(003).ELSE. RP = 'RUPEES'(001).ENDIF
.
  IF ( FINAL = '' ) AND ( DEC = '' ).
    FINAL = 'NIL'.
  ELSEIF ( FINAL = '' ).
    CONCATENATE DEC 'PAISE'(002) INTO FINAL SEPARATED BY ' ' .
  ELSEIF ( DEC = '' ).

    CONCATENATE FINAL RP INTO FINAL SEPARATED BY ' ' .
  ELSE.
    CONCATENATE FINAL RP DEC 'PAISE'(002) INTO FINAL SEPARATED BY ' ' .
  ENDIF.

  TEXT = FINAL.

"""""""""""" End : Convert Amount to Word """"""""""""""""""""



  ENDMETHOD.
ENDCLASS.
