# ✅ Status: Release (v1.5.0)
> **Open Source Contribution:** This project is community-driven and **Open Source**! 🚀  
> If you spot a bug or have an idea for a cool enhancement, your contributions are more than welcome. Feel free to open an **Issue** or submit a **Pull Request**.

![Version](https://img.shields.io/badge/version-1.5.0-blue) 
![ABAP Cloud](https://img.shields.io/badge/ABAP-Cloud%20Ready-green)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://github.com/greltel/ABAP-Cloud-Logger/blob/main/LICENSE)
![ABAP 7.00+](https://img.shields.io/badge/ABAP-7.58%2B-brightgreen)
[![Code Statistics](https://img.shields.io/badge/CodeStatistics-abaplint-blue)](https://abaplint.app/stats/greltel/abap-cloud-logger)

# Table of contents
1. [ABAP Cloud Logger](#ABAP-Cloud-Logger)
2. [Prerequisites](#Prerequisites)
3. [License](#License)
4. [Contributors-Developers](#Contributors-Developers)
5. [Motivation for Creating the Repository](#Motivation-for-Creating-the-Repository)
6. [Usage Examples](#Usage-Examples)
7. [Design Goals-Features](#Design-Goals-Features)
8. [Changelog](#Changelog)
9. [Roadmap](#Roadmap)

# ABAP-Cloud-Logger
ABAP Logger Following Clean Core Principles.ABAP Cloud Logger is a modern, lightweight, and Clean Core-compliant logging library for SAP S/4HANA and SAP BTP ABAP Environment.
It acts as a fluent wrapper around the standard class `CL_BALI_LOG`, simplifying the Application Log API while ensuring strict adherence to **ABAP Cloud** development standards.

# Prerequisites

* SAP S/4HANA 2021 (or higher) OR SAP BTP ABAP Environment.
* XCO library availability

## License
This project is licensed under the [MIT License](https://github.com/greltel/ABAP-Cloud-Logger/blob/main/LICENSE).

## Contributors-Developers
The repository was created by [George Drakos](https://www.linkedin.com/in/george-drakos/).

## Motivation for Creating the Repository

Logging is a tool I rely on almost every day while working with ABAP. I wanted to create a version that is not only simple and effective but also fully compatible with the ABAP Cloud environment. 
The goal is to provide an easy-to-use logger that fits naturally into cloud-ready development practices and can be integrated seamlessly into modern projects.

## Usage Examples

### 1. Initialization
To start logging, get an instance of the logger by providing your Application Log Object and Subobject (defined in Eclipse as Application Log Object).

```abap
DATA(lo_logger) = zcl_cloud_logger=>get_instance( iv_object    = 'Z_CLOUD_LOG_SAMPLE'
                                                  iv_subobject = 'SETUP' ).
```

### 2. Exception Add

```abap
TRY.
    " Your business logic here
    DATA(result) = 100 / 0.

  CATCH cx_sy_zerodivide INTO DATA(lx_error).
    " Pass the exception object to the logger
    lo_logger->log_exception_add( lx_error ).
ENDTRY.
```

### 3. Message Add

```abap
lo_logger->log_message_add( iv_symsg = VALUE #( msgty = 'W'
                                                msgid = 'CL'
                                                msgno = '000'
                                                msgv1 = 'Test Message' ) ).
```
                            
### 4. String Add

```abap
lo_logger->log_string_add( iv_string = 'String Add'
                           iv_msgty  = 'E'  ).
```
### 5. BAPIRET2 Structure and Table Add with Smart Filtering

```abap
lo_logger->log_bapiret2_table_add( 
    it_bapiret2_t   = lt_return
    iv_min_severity = 'E' 
)->save( )

lo_logger->log_bapiret2_structure_add( VALUE #( ) ) .
```

### 6. Advanced Data Logging (JSON)

```abap
SELECT * FROM t001 INTO TABLE @DATA(lt_company_codes) UP TO 10 ROWS.

" Log the whole table as JSON
lo_logger->log_data_add( lt_company_codes )->save_application_log( ).
```

### 7. Get Messages

```abap
DATA(lv_message_count)     = lo_logger->get_message_count( ).

DATA(lt_messages_bapiret2) = lo_logger->get_messages_as_bapiret2( ).

DATA(lt_messages)          = lo_logger->get_messages( ).

DATA(lt_messages_flat)     = lo_logger->get_messages_flat( ).

DATA(lt_messages_rap)      = lo_logger->get_messages_rap( ).
```

### 8. Functional Methods

```abap
DATA(lv_error_exists)   = lo_logger->log_contains_error( ).

DATA(lv_messages_exist) = lo_logger->log_contains_messages( ).

DATA(lv_warning_exists) = lo_logger->log_contains_warning( ).

DATA(lv_is_empty)       = lo_logger->log_is_empty( ).
```

### 9. Get Log Handle

```abap
DATA(lv_handle)         = lo_logger->get_handle( ).

DATA(lv_log_handle)     = lo_logger->get_log_handle( ).
```

### 10. Save Application Log

```abap
lo_logger->save_application_log( ).
```

### 11. Search for a Specific Message

```abap
data(lv_specific_message_exists) = lo_logger->search_message( im_search = VALUE #( msgid = '00' ) ).
```

### 12. Merge Logs

```abap
"Get a New Log Instance
DATA(lo_new_logger) = zcl_cloud_logger=>get_instance( iv_object    = 'Z_MY_OBJECT_NEW'
                                                      iv_subobject = 'Z_MY_SUBOBJECT_NEW' ).

"Add Message
lo_new_logger->log_string_add( iv_string = 'New Logger String'
                               iv_msgty  = 'E'  ).

"Merge with Previous Log
lo_logger->merge_logs( lo_new_logger ).
```

### 13. Reset Log

```abap
lo_logger->reset_appl_log( im_delete_from_db = abap_true ).
```

### 14. Timer

```abap
" 1. Start the stopwatch
lo_logger->start_timer( ).

" 2. Execute a code block
"SELECT FROM.....

" 3. Stop and log the duration automatically
lo_logger->stop_timer( 'Test Timer' ).
```

### 14. Viewer

```abap
lo_logger->display( NEW zcl_cloud_logger_view_alv( ) ).
```

### 15. Sticky Tags

```abap
lo_logger->set_context( 'Order 100' ).
lo_logger->log_string_add( 'Price checked' )."[Order 100] Price checked logged
lo_logger->clear_context( ).
```

## Design Goals-Features

* Install via [ABAPGit](http://abapgit.org)
* ABAP Cloud/Clean Core compatibility.Passed SCI check variant S4HANA_READINESS_2023 and ABAP_CLOUD_READINESS
* Based on [CL_BALI_LOG](https://help.sap.com/docs/btp/sap-business-technology-platform/cl-bali-log-interface-if-bali-log) which is released for Cloud Development (could also use XCO_CP_BAL)
* Based on Multiton Design Pattern for efficient management of log instances
* Unit Tested
* Fluent Interface and method chaining
* Separate logging from viewing using the Strategy Pattern

## Changelog

### [1.5.0] - 2026-01-23
#### Added
 * Added "Sticky Tags" that are automatically appended to all subsequent messages within the instance context. Use set_context and clear_context methods

### [1.4.0] - 2026-01-18
#### Added
* Added support for custom Log Viewers via the `display()` method, enabling UI-agnostic log visualization (Strategy Pattern)

### [1.3.0] - 2026-01-09
#### Added
* Added `start_timer` and `stop_timer` methods for runtime measurement.

### [1.2.0] - 2026-01-07
#### Added
* Enhanced `log_bapiret2_table_add` with `iv_min_severity`. You can now filter logs directly during import (e.g., ignore all Success messages).
  
### [1.1.0] - 2026-01-04
#### Added
* JSON Serialization: New method `log_data_add` allows logging of any data type (Structures/Tables). Data is automatically converted to JSON format using the XCO library.

### [1.0.0] - 2025-12-20
#### Initial Release
* Basic logging capabilities (Messages, Strings, Exceptions).
* Fluent Interface support.
* ABAP Cloud & Clean Core compliance.
* Integration with SAP Application Log (BAL).

## Roadmap

 * Log Distribution Channels: Implementation of a `Sender` interface to route logs to external platforms
 * Notifications: Mechanism to automatically trigger notifications (Email or Technical Events) when a **Critical Error** is logged.
 * Async Performance: Implementation of asynchronous saving for high-volume scenarios to minimize runtime impact.
 * Visualization: Development of a RAP OData Service and a Fiori Dashboard for graphical log analysis and monitoring.
