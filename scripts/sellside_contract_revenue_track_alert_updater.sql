-- USE SCHEMA BI.ALERTS;
USE SCHEMA BI_TEST.ALERTS;
--
-- Revenue tracking alert updater SP
--
-- DROP PROCEDURE ALERTS.SELLSIDE_CONTRACT_REVENUE_TRACK_ALERT_UPDATER ();
CREATE OR REPLACE PROCEDURE SELLSIDE_CONTRACT_REVENUE_TRACK_ALERT_UPDATER ()
RETURNS VARCHAR
LANGUAGE JAVASCRIPT
AS
$$
var snowRet = '', snowSql = `
UPDATE SELLSIDE_CONTRACT_REVENUE_TRACKING D
SET REVENUE_FOUND_TIME = COALESCE(D.REVENUE_FOUND_TIME, CURRENT_TIMESTAMP)
	,DIFF_AMOUNT = ROUND(S.REVENUE - D.REVENUE_FORECAST, 2)
	,DIFF_PERCENTAGE = ROUND(100*((S.REVENUE  - D.REVENUE_FORECAST)/NULLIF(D.REVENUE_FORECAST,0)),2)
	,REVENUE_ACTUAL = S.REVENUE
	,ALERT_STATUS = FALSE
FROM (
      -- revenue having data entered
      SELECT DATA_TS DATA_DATE
        ,PRODUCT_LINE_ID
        ,NETWORK_NAME_ID
        ,CONTRACT_ID
        ,SUM(GROSS_REVENUE) REVENUE
      FROM BI.ACCOUNT_DATA.SELLSIDE_ACCOUNT_DATA_DAILY
      WHERE DATA_DATE >= CURRENT_DATE()-7 -- scope to recent X days of data
      GROUP BY 1,2,3,4
	  HAVING SUM(GROSS_REVENUE) > 0
  ) S
WHERE D.DATA_DATE = S.DATA_DATE
  AND D.PRODUCT_LINE_ID = S.PRODUCT_LINE_ID
  AND D.NETWORK_NAME_ID = S.NETWORK_NAME_ID
  AND D.CONTRACT_ID = S.CONTRACT_ID
  AND D.ALERT_STATUS = TRUE
;`;

try {
  snowRet = snowflake.execute({ sqlText: snowSql });
  snowRet = snowSql;
  }
catch (err) {
  snowRet = "Failure: " + err
  }
finally {
  return snowRet.toString()
  }
$$
;

-- CALL ALERTS.SELLSIDE_CONTRACT_REVENUE_TRACK_ALERT_UPDATER ();
