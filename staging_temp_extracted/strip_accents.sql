-- ==========================================================================
-- Routine Name : strip_accents
-- Routine Type : FUNCTION
-- Dataset      : spatial-vision-343005.staging_temp
-- Created      : 2026-06-23 11:24:00.168000+00:00
-- Last Altered : 2026-06-23 11:24:00.168000+00:00
-- Extracted At : 2026-08-06 13:45:04
-- ==========================================================================

CREATE FUNCTION `spatial-vision-343005`.staging_temp.strip_accents(name STRING) RETURNS STRING
AS (
TRANSLATE(
    name,
    "àáãảạăằắẳẵặâầấẩẫậèéẻẽẹêềếểễệđùúủũụưừứửữựòóỏõọôồốổỗộơờớởỡợìíỉĩịäëïîöüûñçýỳỹỵỷÀÁÃẢẠĂẰẮẲẴẶÂẦẤẨẪẬÈÉẺẼẸÊỀẾỂỄỆĐÙÚỦŨỤƯỪỨỬỮỰÒÓỎÕỌÔỒỐỔỖỘƠỜỚỞỠỢÌÍỈĨỊÄËÏÎÖÜÛÑÇÝỲỸỴỶ",
    "aaaaaaaaaaaaaaaaaeeeeeeeeeeeduuuuuuuuuuuoooooooooooooooooiiiiiaeiiouuncyyyyyaaaaaaaaaaaaaaaaaeeeeeeeeeeeDuuuuuuuuuuuoooooooooooooooooiiiiiaeiiouuncyyyyy"
  )
);
