CREATE PROCEDURE `spatial-vision-343005`.staging_temp.sp_d_api_vnp_branch()
OPTIONS(
  strict_mode=false)
BEGIN

WITH
a AS (
  SELECT
    stt,
    madonvi,
    mataikhoan,
    chinhanh,
    phaply,
    user,
    pass,
    sendername,
    sendermail,
    senderphone,
    senderaddress,
    senderprovincecode,
    senderdistrictcode,
    sendercommunecode,
    status,
    ghichu,
    token,
    type,
    contractcode,
    servicecode,
    contentnote,
    sendtype,
    isbroken,
    deliverytime,
    deliveryrequire,
    deliveryinstruction
  FROM
    `staging.d_api_vnp_branch_test`
   QUALIFY ROW_NUMBER() OVER (PARTITION BY chinhanh,phaply,madonvi ORDER BY created_at DESC) = 1 ),
  b AS (
  SELECT
    chinhanh,
    phaply,
    madonvi,
    MIN(created_at) AS created_at,
    MAX(updated_at) AS updated_at
  FROM
    `staging.d_api_vnp_branch_test`
  GROUP BY
    1,
    2,
    3 )
SELECT
  a.*,
  b.created_at,
  b.updated_at AS last_updated_at
FROM
  a
LEFT JOIN
  b
ON
  a.chinhanh =b.chinhanh and a.phaply=b.phaply and a.madonvi=b.madonvi
;
END;