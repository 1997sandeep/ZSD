CLASS zcl_xml_util DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
   CLASS-METHODS escape_for_xml
      IMPORTING iv_text        TYPE string
      RETURNING VALUE(rv_text) TYPE string.
  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS ZCL_XML_UTIL IMPLEMENTATION.


  METHOD escape_for_xml.
    rv_text = iv_text.
    REPLACE ALL OCCURRENCES OF '&' IN rv_text WITH '&amp;'.
    REPLACE ALL OCCURRENCES OF '<' IN rv_text WITH '&lt;'.
    REPLACE ALL OCCURRENCES OF '>' IN rv_text WITH '&gt;'.
    REPLACE ALL OCCURRENCES OF '"' IN rv_text WITH '&quot;'.
*    REPLACE ALL OCCURRENCES OF ' IN rv_text WITH '&apos;'.
  ENDMETHOD.
ENDCLASS.
