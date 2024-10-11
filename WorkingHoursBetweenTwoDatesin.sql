WITH
  feriados AS (
  SELECT
    date AS fecha,
  IF
    (FORMAT_DATE("%A", date) IN ( 'Sunday')
      OR FORMAT_DATE("%m-%d", date) IN ('01-01',
        '05-01',
        '06-29',
        '07-28',
        '07-29',
        '08-06',
        '08-30',
        '10-08',
        '11-01',
        '12-08',
        '12-09',
        '12-25')
      OR date IN ('2023-04-06',
        '2023-04-07',
        '2024-03-28',
        '2024-03-29',
        '2025-04-17',
        '2025-04-18'), 1, 0) AS T_feriado
  FROM
    UNNEST(GENERATE_DATE_ARRAY('2023-01-01', '2024-12-31')) AS date),
  feriados_2 AS(
  SELECT
    fecha AS feriado
  FROM
    feriados
  WHERE
    T_feriado= 1),
  Sales_task AS (
  SELECT
    DISTINCT *,
    CASE
      WHEN T_SLA >= T_Horas_Gestion THEN 1
      WHEN T_SLA < T_Horas_Gestion THEN 0
  END
    AS TCumplimiento,
  IF
    (T_Horas_Gestion<=24,'00_24',
    IF
      (24 <T_Horas_Gestion
        AND T_Horas_Gestion<=48,'24_48',
      IF
        (48 <T_Horas_Gestion
          AND T_Horas_Gestion<=72,'48_72','72_00' ))) AS Rango_TGestion
  FROM (
    SELECT
      *,
      CASE
        WHEN DATETIME_DIFF(T_CompletedDateTime1, T_CreatedDate1, HOUR)<=9 THEN DATETIME_DIFF(T_CompletedDateTime1, T_CreatedDate1, MINUTE)/60
        ELSE (DATETIME_DIFF(T_CompletedDateTime1, T_CreatedDate1, MINUTE)/60 - (FLOOR(DATETIME_DIFF(T_CompletedDateTime1, T_CreatedDate1, day) /*(
          SELECT
            SUM(T_feriado)
          FROM
            feriados
          WHERE
            fecha >= DATE(T_CreatedDate1)
            AND fecha <= DATE(T_CompletedDateTime1) ) 15)*/- (
        SELECT
          SUM(T_feriado)
        FROM
          feriados
        WHERE
          fecha >= DATE(T_CreatedDate1)
          AND fecha <= DATE(T_CompletedDateTime1) )*24 )))
END
  AS T_Horas_Gestion
FROM (
  SELECT
    DISTINCT /**/CASE
      WHEN EXTRACT(HOUR FROM T_CreatedDate) >= 17 THEN TIMESTAMP_TRUNC( TIMESTAMP_ADD(T_CreatedDate, INTERVAL ( SELECT MIN(dias) FROM UNNEST(GENERATE_ARRAY(1, 5)) AS dias WHERE NOT ( EXTRACT(DAYOFWEEK FROM DATE_ADD(DATE(T_CreatedDate), INTERVAL dias DAY)) IN (1) OR DATE_ADD(DATE(T_CreatedDate), INTERVAL dias DAY) IN ( SELECT feriado FROM feriados_2) ) ) DAY), DAY) + INTERVAL 8 HOUR
      WHEN DATE(T_CreatedDate) IN (
    SELECT
      feriado
    FROM
      feriados_2)
    OR EXTRACT(DAYOFWEEK
    FROM
      DATE(T_CreatedDate)) IN (1) THEN TIMESTAMP_TRUNC( TIMESTAMP_ADD(T_CreatedDate, INTERVAL (
        SELECT
          MIN(dias)
        FROM
          UNNEST(GENERATE_ARRAY(1, 5)) AS dias
        WHERE
          NOT ( EXTRACT(DAYOFWEEK
            FROM
              DATE_ADD(DATE(T_CreatedDate), INTERVAL dias DAY)) IN (1)
            OR DATE_ADD(DATE(T_CreatedDate), INTERVAL dias DAY) IN (
            SELECT
              feriado
            FROM
              feriados_2) ) ) DAY), DAY) + INTERVAL 8 HOUR
      WHEN EXTRACT(HOUR FROM T_CreatedDate) BETWEEN 8 AND 17 THEN T_CreatedDate
      WHEN EXTRACT(HOUR
    FROM
      T_CreatedDate) < 8 THEN TIMESTAMP_TRUNC(T_CreatedDate, DAY) + INTERVAL 8 HOUR
      ELSE T_CreatedDate
  END
    AS T_CreatedDate1,
    CASE
      WHEN EXTRACT(HOUR FROM T_CompletedDateTime) >= 17 THEN TIMESTAMP_TRUNC( TIMESTAMP_ADD( T_CompletedDateTime, INTERVAL ( SELECT MIN(dias) FROM UNNEST(GENERATE_ARRAY(1, 5)) AS dias WHERE NOT ( EXTRACT(DAYOFWEEK FROM DATE_ADD(DATE(T_CompletedDateTime), INTERVAL dias DAY)) IN (1) OR DATE_ADD(DATE(T_CompletedDateTime), INTERVAL dias DAY) IN ( SELECT feriado FROM feriados_2) ) ) DAY ), DAY ) + INTERVAL 8 HOUR
      WHEN DATE(T_CompletedDateTime) IN (
    SELECT
      feriado
    FROM
      feriados_2)
    OR EXTRACT(DAYOFWEEK
    FROM
      DATE(T_CompletedDateTime)) IN (1) THEN TIMESTAMP_TRUNC( TIMESTAMP_ADD( T_CompletedDateTime, INTERVAL (
        SELECT
          MIN(dias)
        FROM
          UNNEST(GENERATE_ARRAY(1, 5)) AS dias
        WHERE
          NOT ( EXTRACT(DAYOFWEEK
            FROM
              DATE_ADD(DATE(T_CompletedDateTime), INTERVAL dias DAY)) IN (1)
            OR DATE_ADD(DATE(T_CompletedDateTime), INTERVAL dias DAY) IN (
            SELECT
              feriado
            FROM
              feriados_2) ) ) DAY ), DAY ) + INTERVAL 8 HOUR
      WHEN EXTRACT(HOUR FROM T_CompletedDateTime) BETWEEN 8 AND 17 THEN T_CompletedDateTime
      WHEN EXTRACT(HOUR
    FROM
      T_CompletedDateTime) < 8 THEN TIMESTAMP_TRUNC(T_CompletedDateTime, DAY) + INTERVAL 8 HOUR
      ELSE T_CompletedDateTime
  END
    AS T_CompletedDateTime1,

  FROM (
    SELECT
      FC_Case__c,
      FC_Number__c,
      DATETIME(TIMESTAMP(CreatedDate), 'America/Lima') AS T_CreatedDate,
      DATETIME(TIMESTAMP(CompletedDateTime), 'America/Lima') AS T_CompletedDateTime,  
    FROM
     TAREA
    QUALIFY
      ROW = 1 ) b

 )))
