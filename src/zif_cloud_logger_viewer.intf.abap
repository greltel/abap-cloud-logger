"! <p class="shorttext synchronized" lang="en">Cloud Logger Viewer</p>
"! Strategy for presenting a logger's entries. Implement it to plug any
"! output channel into {@link zif_cloud_logger.METH:display}.
INTERFACE zif_cloud_logger_viewer
  PUBLIC.

  "! Presents the entries of the given logger.
  "! @parameter logger | Logger whose entries are shown
  METHODS view
    IMPORTING logger TYPE REF TO zif_cloud_logger.

ENDINTERFACE.
