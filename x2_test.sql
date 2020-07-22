WITH SCOPED AS (
    SELECT SEGMENT_ID
        ,DAYSHIFT_ID
        ,NETWORK_ID
//        ,ACCOUNT_ID
//        ,PRODUCT_LINE_ID
        ,SUM(COUNTS) COUNTS
    FROM BI_TEST._TABLE_LOADING.BUYSIDE_ACCOUNT_DATA_INCOMPLETE_DETECTOR_SEGMENT
    WHERE SEGMENT_ID < 2
    GROUP BY SEGMENT_ID
        ,DAYSHIFT_ID
        ,NETWORK_ID
//        ,ACCOUNT_ID
//        ,PRODUCT_LINE_ID
    )
  ,FULL_MAP AS (
    SELECT *
    FROM (SELECT DISTINCT DAYSHIFT_ID FROM SCOPED) B
        ,(SELECT DISTINCT NETWORK_ID FROM SCOPED) N
    //    ,(SELECT DISTINCT ACCOUNT_ID FROM SCOPED) A
    //    ,(SELECT DISTINCT PRODUCT_LINE_ID FROM SCOPED) P
  )
  ,EXPECTED AS (
    SELECT F.NETWORK_ID
//    ,F.ACCOUNT_ID
//    ,F.PRODUCT_LINE_ID
    ,SUM(E.COUNTS)/COUNT(DISTINCT F.DAYSHIFT_ID) COUNTS
    FROM FULL_MAP F
    LEFT JOIN (
        SELECT *
        FROM SCOPED
        WHERE SEGMENT_ID = 1
        ) E
    ON F.DAYSHIFT_ID = E.DAYSHIFT_ID
    AND F.NETWORK_ID = E.NETWORK_ID
//    AND F.ACCOUNT_ID = E.ACCOUNT_ID
//    AND F.PRODUCT_LINE_ID = E.PRODUCT_LINE_ID
    GROUP BY F.NETWORK_ID
    //        ,F.ACCOUNT_ID
    //        ,F.PRODUCT_LINE_ID
    )
  ,OBSERVED AS (
    SELECT F.DAYSHIFT_ID
        ,F.NETWORK_ID
//    ,F.ACCOUNT_ID
//    ,F.PRODUCT_LINE_ID
        ,SUM(E.COUNTS) COUNTS
    FROM FULL_MAP F
    LEFT JOIN (
        SELECT *
        FROM SCOPED
        WHERE SEGMENT_ID = 0
        ) E
    ON F.DAYSHIFT_ID = E.DAYSHIFT_ID
    AND F.NETWORK_ID = E.NETWORK_ID
//    AND F.ACCOUNT_ID = E.ACCOUNT_ID
//    AND F.PRODUCT_LINE_ID = E.PRODUCT_LINE_ID
    GROUP BY F.DAYSHIFT_ID
            ,F.NETWORK_ID
    //        ,F.ACCOUNT_ID
    //        ,F.PRODUCT_LINE_ID
    )
  ,COUNTS_OE2 AS (
     SELECT O.DAYSHIFT_ID
        ,COALESCE(E.NETWORK_ID, O.NETWORK_ID) NETWORK_ID
//        ,COALESCE(E.ACCOUNT_ID, O.ACCOUNT_ID) ACCOUNT_ID
//        ,COALESCE(E.PRODUCT_LINE_ID, O.PRODUCT_LINE_ID) PRODUCT_LINE_ID
        --,O.COUNTS O_COUNTS
        --,E.COUNTS E_COUNTS
        ,COALESCE(SQUARE(COALESCE(O.COUNTS,0) - COALESCE(E.COUNTS,0))/NULLIF(E.COUNTS,0),0) COUNTS_OE2
    FROM OBSERVED O
    JOIN EXPECTED E
    ON O.NETWORK_ID = E.NETWORK_ID
//    AND E.ACCOUNT_ID = O.ACCOUNT_ID
//    AND E.PRODUCT_LINE_ID = O.PRODUCT_LINE_ID
  )
SELECT NETWORK_ID
//    ,ACCOUNT_ID
//    ,PRODUCT_LINE_ID
    ,SUM(COUNTS_OE2) X2_STATSTICS
FROM COUNTS_OE2
GROUP BY NETWORK_ID
//    ,ACCOUNT_ID
//    ,PRODUCT_LINE_ID
ORDER BY NETWORK_ID
//    ,ACCOUNT_ID
//    ,PRODUCT_LINE_ID
;
